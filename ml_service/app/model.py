"""HuggingFace model wrapper for image classification.

The heavy dependencies (torch, transformers) are imported lazily so that
the service can boot and its tests can run in MOCK_INFERENCE mode without
downloading several GB of model weights.
"""
import hashlib
import time

from .config import HF_TOKEN, MOCK_INFERENCE, MODEL_ID
from .logger import get_logger

logger = get_logger("ml_service.model")


class ModelLoadError(RuntimeError):
    """Raised when the HuggingFace model cannot be loaded."""


class ImagePredictor:
    def __init__(self, model_id: str = MODEL_ID, mock: bool = MOCK_INFERENCE):
        self.model_id = model_id
        self.mock = mock
        self._pipe = None
        self._load_attempted = False

    def _load(self):
        if self._pipe is not None:
            return self._pipe
        logger.info("model loading started", {"model": self.model_id})
        started = time.perf_counter()
        try:
            # Heavy imports only on the real path.
            from transformers import pipeline  # noqa

            kwargs = {}
            if HF_TOKEN:
                kwargs["token"] = HF_TOKEN
            self._pipe = pipeline(
                "image-classification",
                model=self.model_id,
                **kwargs,
            )
        except Exception as err:  # noqa: BLE001 - surface as controlled error
            logger.error(
                "model loading failed",
                {"model": self.model_id, "errorMessage": str(err)},
            )
            raise ModelLoadError(
                f"Failed to load the model '{self.model_id}'. "
                "Ensure it is publicly accessible and that credentials are set."
            ) from err
        duration_ms = int((time.perf_counter() - started) * 1000)
        logger.info(
            "model loading completed",
            {"model": self.model_id, "durationMs": duration_ms},
        )
        return self._pipe

    def predict_pil(self, image):
        """Classify a PIL image and return a normalized prediction dict."""
        started = time.perf_counter()
        if self.mock:
            verdict, confidence, label = self._mock_predict(image)
        else:
            pipe = self._load()
            try:
                output = pipe(image)
            except Exception as err:  # noqa: BLE001
                logger.error(
                    "inference failed",
                    {"model": self.model_id, "errorMessage": str(err)},
                )
                raise RuntimeError("Model inference failed on the provided image.") from err
            best = max(output, key=lambda item: item.get("score", 0))
            raw_label = str(best.get("label", "")).strip().lower()
            confidence = round(float(best.get("score", 0)) * 100, 1)
            if any(token in raw_label for token in ("fake", "ai", "synthetic", "deepfake", "selected")):
                verdict, label = "AI", "AI Generated"
            else:
                verdict, label = "Real", "Real / Human-made"
        duration_ms = int((time.perf_counter() - started) * 1000)
        logger.info(
            "inference completed",
            {
                "model": self.model_id,
                "verdict": verdict,
                "confidence": confidence,
                "durationMs": duration_ms,
                "mock": self.mock,
            },
        )
        return {
            "verdict": verdict,
            "confidence": confidence,
            "label": label,
            "modelName": "mock-inference" if self.mock else self.model_id,
            "processingMs": duration_ms,
        }

    @staticmethod
    def _mock_predict(image):
        data = image.tobytes()
        digest = hashlib.sha256(data).digest()
        seed = int.from_bytes(digest[:4], "big")
        fake = seed % 3 == 0
        confidence = round(50 + (seed % 40) + (data[0] if data else 0) % 10, 1)
        if fake:
            return "AI", min(confidence, 99.0), "AI Generated"
        return "Real", round(100 - min(confidence, 99.0), 1), "Real / Human-made"


_predictor = None


def get_predictor():
    """Process-wide singleton predictor."""
    global _predictor
    if _predictor is None:
        _predictor = ImagePredictor()
    return _predictor