"""Inference endpoints.

Three prediction routes:
  POST /predict/image  -- classify a raw image (Model 01 / Model 04)
  POST /predict/face   -- detect faces, crop each, classify (Model 02)
  POST /predict/video  -- sample frames, detect faces per frame, classify (Model 03)

All routes accept multipart/form-data with a `file` field and return
PredictionResponse JSON.
"""
import io
import os
import time

from fastapi import APIRouter, File, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from starlette.concurrency import run_in_threadpool

from .config import (
    MAX_IMAGE_SIZE,
    MAX_VIDEO_SIZE,
    MOCK_INFERENCE,
    MODEL_ID,
    USE_LOCAL_MODEL,
    FRAME_SAMPLE_INTERVAL,
)
from .logger import get_logger
from .model import ModelLoadError, get_predictor
from .local_model import LocalModelLoadError, get_local_predictor
from .schemas import PredictionResponse, PredictionData

router = APIRouter(tags=["prediction"])
logger = get_logger("ml_service.predict")


def _get_active_predictor():
    """Return the currently configured predictor (local or HuggingFace)."""
    if USE_LOCAL_MODEL:
        return get_local_predictor()
    return get_predictor()


ALLOWED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".tiff", ".tif", ".bmp", ".avif"}
ALLOWED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".webm"}

# Face detection padding fraction added around each detected face crop.
_FACE_PAD = 0.20
# Minimum face region size in pixels to skip too-tiny detections.
_MIN_FACE_PX = 40


def _extension(filename):
    return os.path.splitext((filename or "").lower())[1]


def _http_error(status: int, code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=status,
        detail={"message": message, "error": {"code": code}},
    )


def _validate_image_upload(filename, size) -> None:
    if size == 0:
        raise _http_error(422, "EMPTY_FILE", "The uploaded file is empty.")
    if size > MAX_IMAGE_SIZE:
        raise _http_error(413, "FILE_TOO_LARGE", "Image exceeds the maximum allowed size.")
    if _extension(filename) not in ALLOWED_IMAGE_EXTENSIONS:
        raise _http_error(422, "INVALID_FILE_TYPE", "Unsupported image format.")


def _validate_video_upload(filename, size) -> None:
    if size == 0:
        raise _http_error(422, "EMPTY_FILE", "The uploaded file is empty.")
    if size > MAX_VIDEO_SIZE:
        raise _http_error(413, "FILE_TOO_LARGE", "Video exceeds the maximum allowed size.")
    if _extension(filename) not in ALLOWED_VIDEO_EXTENSIONS:
        raise _http_error(422, "INVALID_FILE_TYPE", "Unsupported video format.")


def _open_image(bytes_buffer):
    """Open + verify a PIL image; raises a controlled 422 for corrupt input."""
    try:
        image = Image.open(bytes_buffer)
        image.load()
        return image.convert("RGB")
    except UnidentifiedImageError as err:
        raise _http_error(422, "INVALID_IMAGE", "The file is not a valid image.") from err
    except Exception as err:  # noqa: BLE001
        logger.error("image decode failed", {"errorMessage": str(err)})
        raise _http_error(422, "CORRUPTED_IMAGE", "The image appears to be corrupted.") from err


# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Face detection helpers (YuNet DNN detector with Haar cascade fallback)
# ---------------------------------------------------------------------------

_YUNET_MODEL_PATH = os.path.join(
    os.path.dirname(__file__), "..", "models", "face_detection_yunet_2023mar.onnx"
)


def _detect_face_regions(cv2, np, cv_image):
    """
    Detect face bounding boxes using YuNet DNN (or Haar cascade fallback).
    Returns a list of (x, y, w, h) tuples (BGR input expected).
    """
    h, w = cv_image.shape[:2]

    # Strategy 1: YuNet DNN face detector (highly accurate, fast, supports OpenCV 4.x & 5.x)
    if os.path.exists(_YUNET_MODEL_PATH) and hasattr(cv2, "FaceDetectorYN_create"):
        try:
            detector = cv2.FaceDetectorYN_create(
                _YUNET_MODEL_PATH,
                "",
                (w, h),
                score_threshold=0.5,
                nms_threshold=0.3,
                top_k=50,
            )
            _, faces = detector.detect(cv_image)
            if faces is not None and len(faces) > 0:
                regions = []
                for f in faces:
                    fx, fy, fw, fh = int(f[0]), int(f[1]), int(f[2]), int(f[3])
                    if fw >= _MIN_FACE_PX and fh >= _MIN_FACE_PX:
                        regions.append((max(0, fx), max(0, fy), fw, fh))
                return regions
        except Exception as e:
            logger.warning("YuNet face detection error, falling back", {"error": str(e)})

    # Strategy 2: Haar cascade classifier if available in this OpenCV build
    if hasattr(cv2, "CascadeClassifier") and hasattr(cv2, "data") and hasattr(cv2.data, "haarcascades"):
        try:
            gray = cv2.cvtColor(cv_image, cv2.COLOR_BGR2GRAY)
            cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
            cascade = cv2.CascadeClassifier(cascade_path)
            faces = cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=4,
                minSize=(_MIN_FACE_PX, _MIN_FACE_PX),
                flags=cv2.CASCADE_SCALE_IMAGE,
            )
            if len(faces) > 0:
                return [(int(x), int(y), int(w), int(h)) for (x, y, w, h) in faces]
        except Exception:
            pass

    return []


def _crop_face(pil_image, x, y, w, h, pad=_FACE_PAD):
    """Crop a face region from a PIL RGB image with padding."""
    iw, ih = pil_image.size
    pad_px_w = int(w * pad)
    pad_px_h = int(h * pad)
    x1 = max(0, x - pad_px_w)
    y1 = max(0, y - pad_px_h)
    x2 = min(iw, x + w + pad_px_w)
    y2 = min(ih, y + h + pad_px_h)
    return pil_image.crop((x1, y1, x2, y2))


def _extract_face_crops_from_pil(pil_image):
    """
    Detect faces in a PIL RGB image using OpenCV.
    Returns (face_crops: list[PIL.Image], num_faces: int).
    If no faces are found, returns ([full_image], 0) so inference still runs.
    """
    try:
        import cv2
        import numpy as np
    except ImportError:
        # OpenCV not installed -- skip face detection, use full image.
        return [pil_image], 0

    cv_bgr = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
    regions = _detect_face_regions(cv2, np, cv_bgr)
    if not regions:
        return [pil_image], 0

    crops = [_crop_face(pil_image, x, y, w, h) for (x, y, w, h) in regions]
    return crops, len(regions)


def _aggregate_face_results(results: list[dict], num_faces: int) -> dict:
    """
    Aggregate per-face predictions into a single verdict.
    Majority vote; ties go to AI (conservative).
    """
    if not results:
        return None
    ai_results = [r for r in results if r["verdict"] == "AI"]
    real_results = [r for r in results if r["verdict"] == "Real"]
    total = len(results)
    ai_share = len(ai_results) / total

    if ai_share >= 0.5:
        # At least half of faces are flagged as AI
        avg_conf = round(sum(r["confidence"] for r in ai_results) / len(ai_results), 1)
        label_suffix = f" ({len(ai_results)}/{total} face(s) flagged)" if total > 1 else ""
        return {
            "prediction": "AI Generated",
            "verdict": "AI",
            "confidence": avg_conf,
            "label": f"AI Generated{label_suffix}",
            "rawLabel": "Fake",
            "model": results[0]["model"],
            "modelName": results[0]["modelName"],
            "processingMs": sum(r["processingMs"] for r in results),
            "facesDetected": num_faces,
        }
    else:
        avg_conf = round(sum(r["confidence"] for r in real_results) / len(real_results), 1)
        label_suffix = f" ({len(real_results)}/{total} face(s) authentic)" if total > 1 else ""
        return {
            "prediction": "Real / Human-made",
            "verdict": "Real",
            "confidence": avg_conf,
            "label": f"Real / Human-made{label_suffix}",
            "rawLabel": "Real",
            "model": results[0]["model"],
            "modelName": results[0]["modelName"],
            "processingMs": sum(r["processingMs"] for r in results),
            "facesDetected": num_faces,
        }


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@router.get("/health")
def health():
    active_model = "local/deepfake_efficientnet_b0" if USE_LOCAL_MODEL else MODEL_ID
    return {"status": "ok", "model": active_model, "mock": MOCK_INFERENCE, "useLocalModel": USE_LOCAL_MODEL}


# ── Route 1: Raw image (Model 01 / Model 04) ────────────────────────────────

@router.post(
    "/predict/image",
    response_model=PredictionResponse,
    responses={
        413: {"description": "File too large"},
        422: {"description": "Invalid / corrupted image"},
        503: {"description": "Model not loaded"},
    },
)
async def predict_image(
    file: UploadFile = File(..., description="Image file (PNG, JPEG, WEBP, GIF, TIFF, BMP)"),
):
    request_id = file.headers.get("x-request-id")
    logger.info("prediction started", {"media": "image", "filename": file.filename, "requestId": request_id})
    started = time.perf_counter()

    _validate_image_upload(file.filename, file.size or 0)
    raw = await file.read()
    image = await run_in_threadpool(_open_image, io.BytesIO(raw))

    try:
        predictor = _get_active_predictor()
        result = await run_in_threadpool(predictor.predict_pil, image)
    except (ModelLoadError, LocalModelLoadError) as err:
        raise _http_error(503, "MODEL_LOAD_ERROR", str(err)) from err
    except RuntimeError as err:
        raise _http_error(502, "INFERENCE_ERROR", "Model inference failed on the provided image.") from err

    logger.info(
        "prediction completed",
        {
            "media": "image",
            "requestId": request_id,
            "verdict": result["verdict"],
            "durationMs": int((time.perf_counter() - started) * 1000),
        },
    )
    return PredictionResponse(message="Detection completed.", data=PredictionData(**result))


# ── Route 2: Face deepfake (Model 02) ────────────────────────────────────────
# Detects faces, crops each one, runs inference per face, aggregates verdict.

@router.post(
    "/predict/face",
    response_model=PredictionResponse,
    responses={
        413: {"description": "File too large"},
        422: {"description": "Invalid / corrupted image or no face found"},
        503: {"description": "Model not loaded"},
    },
)
async def predict_face(
    file: UploadFile = File(..., description="Photo containing one or more faces (PNG, JPEG, WEBP ...)"),
):
    request_id = file.headers.get("x-request-id")
    logger.info("face prediction started", {"filename": file.filename, "requestId": request_id})
    started = time.perf_counter()

    _validate_image_upload(file.filename, file.size or 0)
    raw = await file.read()
    image = await run_in_threadpool(_open_image, io.BytesIO(raw))

    # Extract face crops (falls back to full image when OpenCV is absent / no face)
    face_crops, num_faces = await run_in_threadpool(_extract_face_crops_from_pil, image)
    logger.info("face detection completed", {"facesDetected": num_faces, "requestId": request_id})

    if MOCK_INFERENCE:
        # Mock mode: run predictor on each crop.
        predictor = _get_active_predictor()
        results = [predictor.predict_pil(crop) for crop in face_crops]
    else:
        try:
            predictor = _get_active_predictor()
            results = []
            for crop in face_crops:
                results.append(await run_in_threadpool(predictor.predict_pil, crop))
        except (ModelLoadError, LocalModelLoadError) as err:
            raise _http_error(503, "MODEL_LOAD_ERROR", str(err)) from err
        except RuntimeError as err:
            raise _http_error(502, "INFERENCE_ERROR", "Face deepfake inference failed.") from err

    result = _aggregate_face_results(results, num_faces)
    if result is None:
        raise _http_error(422, "NO_FACES", "No faces could be detected in the uploaded image.")

    logger.info(
        "face prediction completed",
        {
            "requestId": request_id,
            "facesDetected": num_faces,
            "verdict": result["verdict"],
            "confidence": result["confidence"],
            "durationMs": int((time.perf_counter() - started) * 1000),
        },
    )
    return PredictionResponse(message="Face deepfake detection completed.", data=PredictionData(**result))


# ── Route 3: Video deepfake (Model 03) ────────────────────────────────────────
# Samples frames -> detects faces per frame -> runs inference per face crop.

@router.post(
    "/predict/video",
    response_model=PredictionResponse,
    responses={
        413: {"description": "File too large"},
        422: {"description": "Invalid video"},
        503: {"description": "Model not loaded"},
    },
)
async def predict_video(
    file: UploadFile = File(..., description="Video file (MP4, MOV, AVI, MKV, WEBM)"),
):
    request_id = file.headers.get("x-request-id")
    logger.info("video prediction started", {"filename": file.filename, "requestId": request_id})
    started = time.perf_counter()

    _validate_video_upload(file.filename, file.size or 0)
    raw = await file.read()

    predictor = _get_active_predictor()
    if predictor.mock:
        # Mock path needs no OpenCV or model weights.
        image = Image.frombytes("RGB", (8, 8), raw[:192].ljust(192, b"\x00"))
        result = predictor.predict_pil(image)
        result["framesAnalyzed"] = 1
        result["facesDetected"] = 0
    else:
        try:
            import cv2  # noqa
            import numpy as np
        except ImportError as err:  # noqa: BLE001
            raise _http_error(503, "MISSING_OPENCV", "Video processing support is not installed.") from err

        frames = await run_in_threadpool(_extract_frames, np, raw)
        if not frames:
            raise _http_error(422, "INVALID_VIDEO", "No readable frames found in the video.")

        frames = frames[: FRAME_SAMPLE_INTERVAL * 120]
        all_results = []
        total_faces = 0

        for frame in frames:
            # Extract faces from this frame; fall back to full frame if no face.
            face_crops, num_faces = _extract_face_crops_from_pil(frame)
            total_faces += num_faces
            for crop in face_crops:
                try:
                    all_results.append(predictor.predict_pil(crop))
                except RuntimeError as err:
                    raise _http_error(502, "INFERENCE_ERROR", "Frame inference failed.") from err

        if not all_results:
            raise _http_error(422, "NO_CONTENT", "Could not extract any analyzable content from the video.")

        ai_results = [r for r in all_results if r["verdict"] == "AI"]
        real_results = [r for r in all_results if r["verdict"] == "Real"]
        total = len(all_results)
        ai_share = len(ai_results) / total
        avg_ai_conf = round(sum(r["confidence"] for r in ai_results) / len(ai_results), 1) if ai_results else 0.0
        avg_real_conf = round(sum(r["confidence"] for r in real_results) / len(real_results), 1) if real_results else 0.0

        result = {
            "prediction": "AI Generated" if ai_share >= 0.5 else "Real / Human-made",
            "verdict": "AI" if ai_share >= 0.5 else "Real",
            "confidence": avg_ai_conf if ai_share >= 0.5 else avg_real_conf,
            "label": (
                f"AI Generated ({ai_share:.0%} of face-crops flagged)"
                if ai_share >= 0.5
                else f"Real / Human-made ({1 - ai_share:.0%} of face-crops authentic)"
            ),
            "rawLabel": "Fake" if ai_share >= 0.5 else "Real",
            "model": "local/deepfake_efficientnet_b0" if USE_LOCAL_MODEL else MODEL_ID,
            "modelName": "EfficientNet-B0 (Local)" if USE_LOCAL_MODEL else MODEL_ID,
            "processingMs": int((time.perf_counter() - started) * 1000),
            "framesAnalyzed": len(frames),
            "facesDetected": total_faces,
        }

    logger.info(
        "video prediction completed",
        {
            "requestId": request_id,
            "verdict": result["verdict"],
            "framesAnalyzed": result.get("framesAnalyzed"),
            "facesDetected": result.get("facesDetected"),
            "durationMs": int((time.perf_counter() - started) * 1000),
        },
    )
    return PredictionResponse(message="Video deepfake detection completed.", data=PredictionData(**result))


def _extract_frames(np, raw_bytes, step=FRAME_SAMPLE_INTERVAL):
    """Sample every Nth frame from a video as PIL RGB images."""
    import cv2
    import tempfile, os

    # Write to temp file so cv2 can seek (in-memory buffer is not seekable)
    suffix = ".mp4"
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    try:
        tmp.write(raw_bytes)
        tmp.flush()
        tmp.close()
        cap = cv2.VideoCapture(tmp.name)
        frames = []
        try:
            index = 0
            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                if index % step == 0:
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    frames.append(Image.fromarray(rgb))
                index += 1
        finally:
            cap.release()
    finally:
        os.unlink(tmp.name)
    return frames
