"""Local EfficientNet-B0 model loader for AI/deepfake image detection.

Loads ``ml_service/models/deepfake_efficientnet_b0.pt`` -- a PyTorch checkpoint
fine-tuned for binary AI-vs-Real image classification with ~96% accuracy.

Checkpoint format (dict with keys):
    model_name         : "efficientnet_b0"
    model_state_dict   : OrderedDict of 360 tensors
    label_to_index     : {"Fake": 0, "Real": 1}
    image_size         : 224
    mean               : [0.485, 0.456, 0.406]
    std                : [0.229, 0.224, 0.225]
    validation_accuracy: 0.9599  (~96%)

Class mapping:  index 0 ? Fake/AI Generated
                index 1 ? Real / Human-made
"""
from __future__ import annotations

import os
import time
from pathlib import Path

from .config import MOCK_INFERENCE
from .logger import get_logger

logger = get_logger("ml_service.local_model")

_DEFAULT_MODEL_PATH = Path(__file__).parent.parent / "models" / "deepfake_efficientnet_b0.pt"
LOCAL_MODEL_PATH = Path(os.getenv("LOCAL_MODEL_PATH", str(_DEFAULT_MODEL_PATH)))

# Fallback normalization (the checkpoint stores its own -- used only if missing)
_IMAGENET_MEAN = [0.485, 0.456, 0.406]
_IMAGENET_STD = [0.229, 0.224, 0.225]
_INPUT_SIZE = 224


class LocalModelLoadError(RuntimeError):
    """Raised when the local EfficientNet checkpoint cannot be loaded."""


class LocalEfficientNetPredictor:
    """Wraps the locally stored EfficientNet-B0 deepfake-detection checkpoint."""

    def __init__(self, model_path: Path = LOCAL_MODEL_PATH, mock: bool = MOCK_INFERENCE):
        self.model_path = model_path
        self.mock = mock
        self._model = None
        self._transform = None
        self._device = "cpu"
        # label_to_index from checkpoint: {"Fake": 0, "Real": 1}
        # We invert it to index_to_label for prediction.
        self._index_to_label: dict = {0: "Fake", 1: "Real"}

    def _pick_device(self) -> str:
        try:
            import torch
            if torch.cuda.is_available():
                return "cuda"
        except Exception:
            pass
        return "cpu"

    def _build_transform(self, image_size: int, mean: list, std: list):
        from torchvision import transforms
        return transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.ToTensor(),
            transforms.Normalize(mean=mean, std=std),
        ])

    def _build_efficientnet(self, num_classes: int = 2):
        from torchvision.models import efficientnet_b0
        import torch.nn as nn
        model = efficientnet_b0(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(in_features, num_classes)
        return model

    def _load(self):
        """Load the checkpoint from disk (idempotent)."""
        if self._model is not None:
            return self._model

        if not self.model_path.exists():
            raise LocalModelLoadError(
                f"Local model file not found: {self.model_path}. "
                "Please ensure deepfake_efficientnet_b0.pt is in ml_service/models/."
            )

        logger.info("local model loading started", {"path": str(self.model_path)})
        started = time.perf_counter()

        try:
            import torch
            self._device = self._pick_device()
            checkpoint = torch.load(self.model_path, map_location=self._device, weights_only=False)

            # -- Extract metadata stored in the checkpoint ------------------
            if not isinstance(checkpoint, dict) or "model_state_dict" not in checkpoint:
                raise LocalModelLoadError(
                    f"Unexpected checkpoint format in {self.model_path}. "
                    "Expected a dict with 'model_state_dict' key."
                )

            state_dict = checkpoint["model_state_dict"]
            image_size = checkpoint.get("image_size", _INPUT_SIZE)
            mean = checkpoint.get("mean", _IMAGENET_MEAN)
            std = checkpoint.get("std", _IMAGENET_STD)

            # Build label mapping: invert label_to_index ? index_to_label
            label_to_index = checkpoint.get("label_to_index", {"Fake": 0, "Real": 1})
            self._index_to_label = {v: k for k, v in label_to_index.items()}

            # Determine num_classes from the final classifier layer
            classifier_weight = state_dict.get("classifier.1.weight")
            num_classes = classifier_weight.shape[0] if classifier_weight is not None else 2

            # -- Build and populate the model -------------------------------
            model = self._build_efficientnet(num_classes=num_classes)
            # Strip DataParallel "module." prefix if present
            cleaned = {k.replace("module.", ""): v for k, v in state_dict.items()}
            missing, unexpected = model.load_state_dict(cleaned, strict=True)
            if missing:
                logger.warning("missing keys after load", {"keys": missing[:5]})
            if unexpected:
                logger.warning("unexpected keys after load", {"keys": unexpected[:5]})

            model.to(self._device)
            model.eval()
            self._model = model
            self._transform = self._build_transform(image_size, mean, std)

            logger.info(
                "local model loading completed",
                {
                    "path": str(self.model_path),
                    "device": self._device,
                    "numClasses": num_classes,
                    "labels": self._index_to_label,
                    "durationMs": int((time.perf_counter() - started) * 1000),
                },
            )

        except LocalModelLoadError:
            raise
        except Exception as err:
            logger.error("local model loading failed", {"error": str(err)})
            raise LocalModelLoadError(
                f"Failed to load local model from {self.model_path}: {err}"
            ) from err

        return self._model

    def load(self):
        """Preload the model eagerly (idempotent). Called at service startup."""
        if not self.mock:
            self._load()

    def predict_pil(self, image) -> dict:
        """Classify a PIL image. Returns the same response dict as HF predictor."""
        started = time.perf_counter()

        if self.mock:
            verdict, confidence, label = self._mock_predict(image)
            raw_label = label
        else:
            model = self._load()
            try:
                import torch
                tensor = self._transform(image).unsqueeze(0).to(self._device)
                with torch.no_grad():
                    logits = model(tensor)
                probs = torch.softmax(logits, dim=-1)[0]
                best_index = int(torch.argmax(probs).item())
                confidence = round(float(probs[best_index].item()) * 100, 1)
                raw_label = self._index_to_label.get(best_index, str(best_index))
                verdict, label = self._map_label(raw_label, best_index)
            except Exception as err:
                logger.error("local model inference failed", {"error": str(err)})
                raise RuntimeError("Local model inference failed on the provided image.") from err

        duration_ms = int((time.perf_counter() - started) * 1000)
        logger.info(
            "local model inference completed",
            {"verdict": verdict, "confidence": confidence, "durationMs": duration_ms, "mock": self.mock},
        )
        return {
            "prediction": label,
            "verdict": verdict,
            "confidence": confidence,
            "label": label,
            "rawLabel": raw_label,
            "model": "local/deepfake_efficientnet_b0",
            "modelName": "EfficientNet-B0 (Local, ~96% acc)",
            "processingMs": duration_ms,
        }

    def _map_label(self, raw_label: str, class_index: int) -> tuple:
        """
        Map raw label to (verdict, display_label).

        Checkpoint label mapping:
            index 0 ? "Fake"  ? verdict "AI"   ? display "AI Generated"
            index 1 ? "Real"  ? verdict "Real"  ? display "Real / Human-made"
        """
        normalized = str(raw_label).strip().lower()
        if normalized in ("fake", "ai", "deepfake", "generated", "synthetic") or class_index == 0:
            return "AI", "AI Generated"
        return "Real", "Real / Human-made"

    @staticmethod
    def _mock_predict(image):
        import hashlib
        data = image.tobytes()
        digest = hashlib.sha256(data).digest()
        seed = int.from_bytes(digest[:4], "big")
        fake = seed % 3 == 0
        confidence = round(50 + (seed % 40) + (data[0] if data else 0) % 10, 1)
        if fake:
            return "AI", min(confidence, 99.0), "AI Generated"
        return "Real", round(100 - min(confidence, 99.0), 1), "Real / Human-made"


# -- Process-wide singleton ----------------------------------------------------
_local_predictor: "LocalEfficientNetPredictor | None" = None


def get_local_predictor() -> "LocalEfficientNetPredictor":
    """Return (or create) the process-wide local model predictor."""
    global _local_predictor
    if _local_predictor is None:
        _local_predictor = LocalEfficientNetPredictor()
    return _local_predictor
