"""Inference endpoints. Accept multipart file uploads, validate them and
return a structured prediction response."""
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
    FRAME_SAMPLE_INTERVAL,
)
from .logger import get_logger
from .model import ModelLoadError, get_predictor
from .schemas import PredictionResponse, PredictionData

router = APIRouter(tags=["prediction"])
logger = get_logger("ml_service.predict")

ALLOWED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".tiff", ".tif", ".bmp", ".avif"}
ALLOWED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".webm"}


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


@router.get("/health")
def health():
    return {"status": "ok", "model": MODEL_ID, "mock": MOCK_INFERENCE}


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
    media = "image"
    logger.info("prediction started", {"media": media, "filename": file.filename, "requestId": request_id})
    started = time.perf_counter()

    _validate_image_upload(file.filename, file.size or 0)
    raw = await file.read()
    image = await run_in_threadpool(_open_image, io.BytesIO(raw))

    try:
        predictor = get_predictor()
        result = await run_in_threadpool(predictor.predict_pil, image)
    except ModelLoadError as err:
        raise _http_error(503, "MODEL_LOAD_ERROR", str(err)) from err
    except RuntimeError as err:
        raise _http_error(502, "INFERENCE_ERROR", "Model inference failed on the provided image.") from err

    logger.info(
        "prediction completed",
        {
            "media": media,
            "requestId": request_id,
            "verdict": result["verdict"],
            "durationMs": int((time.perf_counter() - started) * 1000),
        },
    )
    return PredictionResponse(message="Detection completed.", data=PredictionData(**result))


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
    file: UploadFile = File(..., description="Video file (MP4, MOV, AVI, MKW, WEBM)"),
):
    request_id = file.headers.get("x-request-id")
    media = "video"
    logger.info("prediction started", {"media": media, "filename": file.filename, "requestId": request_id})
    started = time.perf_counter()

    _validate_video_upload(file.filename, file.size or 0)
    raw = await file.read()

    predictor = get_predictor()
    if predictor.mock:
        # Mock path needs no OpenCV or model weights.
        image = Image.frombytes("RGB", (8, 8), raw[:192].ljust(192, b"\x00"))
        result = predictor.predict_pil(image)
        result["framesAnalyzed"] = 1
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
        results = []
        for frame in frames:
            try:
                results.append(predictor.predict_pil(frame))
            except RuntimeError as err:
                raise _http_error(502, "INFERENCE_ERROR", "Frame inference failed.") from err

        ai_scores = [r["confidence"] for r in results if r["verdict"] == "AI"]
        real_scores = [r["confidence"] for r in results if r["verdict"] == "Real"]
        total = len(results)
        ai_share = len(ai_scores) / total
        result = {
            "verdict": "AI" if ai_share >= 0.5 else "Real",
            "confidence": round(sum(ai_scores) / total, 1)
            if ai_share >= 0.5
            else round(sum(real_scores) / total, 1),
            "label": ("AI Generated" if ai_share >= 0.5 else "Real / Human-made")
            + f" ({ai_share:.0%} frames flagged)",
            "modelName": MODEL_ID,
            "processingMs": int((time.perf_counter() - started) * 1000),
            "framesAnalyzed": total,
        }

    logger.info(
        "prediction completed",
        {
            "media": media,
            "requestId": request_id,
            "verdict": result["verdict"],
            "durationMs": int((time.perf_counter() - started) * 1000),
        },
    )
    return PredictionResponse(message="Detection completed.", data=PredictionData(**result))


def _extract_frames(np, raw_bytes, step=FRAME_SAMPLE_INTERVAL):
    import cv2

    buffer = np.frombuffer(raw_bytes, dtype=np.uint8)
    cap = cv2.VideoCapture(buffer)
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
    return frames