"""HuggingFace model wrapper for image classification.

Runs `AutoImageProcessor` + `AutoModelForImageClassification` (ViT) behind a
lazy-loading singleton so the model is downloaded/loaded at most once per
process. CUDA is used automatically when available; otherwise the model runs
on CPU. The heavy dependencies (torch, transformers) are imported lazily so
that the service can boot and its tests can run in MOCK_INFERENCE mode without
downloading several GB of model weights.
"""
import hashlib
import time

from .config import HF_TOKEN, MOCK_INFERENCE, MODEL_ID
from .logger import get_logger

logger = get_logger("ml_service.model")

# Tokens that identify an "AI generated" class in the model's own labels.
_AI_TOKENS = ("fake", "ai", "synthetic", "deepfake", "selected", "generated")


class ModelLoadError(RuntimeError):
    """Raised when the HuggingFace model cannot be loaded."""


class ImagePredictor:
    def __init__(self, model_id: str = MODEL_ID, mock: bool = MOCK_INFERENCE):
        self.model_id = model_id
        self.mock = mock
        self._model = None
        self._processor = None
        self._device = "cpu"
        self._id2label = None
        self._load_attempted = False

    def _pick_device(self):
        """Return 'cuda' when a CUDA-capable GPU is available, else 'cpu'."""
        try:
            import torch

            if torch.cuda.is_available():
                return "cuda"
        except Exception:  # noqa: BLE001 - torch missing/corrupt -> CPU fallback
            pass
        return "cpu"

    def _load(self):
        if self._model is not None:
            return self._model, self._processor
        logger.info("model loading started", {"model": self.model_id})
        started = time.perf_counter()
        try:
            # Heavy imports only on the real path.
            from transformers import AutoImageProcessor, AutoModelForImageClassification

            self._device = self._pick_device()
            # Pass HF_TOKEN so gated / private models can be downloaded.
            token = HF_TOKEN or None
            self._processor = AutoImageProcessor.from_pretrained(
                self.model_id, token=token,
            )
            self._model = AutoModelForImageClassification.from_pretrained(
                self.model_id, token=token,
            )
            self._model.to(self._device)
            self._model.eval()
            self._id2label = self._model.config.id2label
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
            {"model": self.model_id, "durationMs": duration_ms, "device": self._device},
        )
        return self._model, self._processor

    def load(self):
        """Preload the model (idempotent). Used at FastAPI startup."""
        if not self.mock:
            self._load()

    def _max_class(self, logits):
        """Return (raw_label, confidence_pct) of the highest-probability class."""
        import torch

        probs = torch.softmax(logits, dim=-1)[0]
        best_index = int(torch.argmax(probs).item())
        confidence = round(float(probs[best_index].item()) * 100, 1)
        # config.id2label keys may be strings ("0") or ints (0); accept both.
        raw_label = (
            self._id2label.get(str(best_index))
            or self._id2label.get(best_index)
            or str(best_index)
        )
        return raw_label, confidence

    @staticmethod
    def _map_label(raw_label):
        """Map the model's own label to the app's 'AI'/'Real' verdict + label."""
        normalized = str(raw_label).strip().lower()
        if any(token in normalized for token in _AI_TOKENS):
            return "AI", "AI Generated"
        return "Real", "Real / Human-made"

    def predict_pil(self, image):
        """Classify a PIL image and return a normalized prediction dict."""
        started = time.perf_counter()
        if self.mock:
            verdict, confidence, label = self._mock_predict(image)
            raw_label = label
        else:
            model, processor = self._load()
            try:
                import torch

                inputs = processor(images=image, return_tensors="pt")
                if self._device == "cuda":
                    inputs = {key: value.to(self._device) for key, value in inputs.items()}
                with torch.no_grad():
                    outputs = model(**inputs)
                raw_label, confidence = self._max_class(outputs.logits)
            except Exception as err:  # noqa: BLE001
                logger.error(
                    "inference failed",
                    {"model": self.model_id, "errorMessage": str(err)},
                )
                raise RuntimeError("Model inference failed on the provided image.") from err
            verdict, label = self._map_label(raw_label)
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
            "prediction": label,
            "verdict": verdict,
            "confidence": confidence,
            "label": label,
            "rawLabel": raw_label,
            "model": self.model_id,
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