"""Service configuration.

Read from environment variables (optionally loaded from a `.env` file).
Never commit real secrets.
"""
import os

from dotenv import load_dotenv

load_dotenv()


def _bool(value, default=False):
    if value is None:
        return default
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _int(value, default):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


MODEL_ID = os.getenv("MODEL_ID", "dima806/deepfake_vs_real_image_detection")
HF_TOKEN = os.getenv("HF_TOKEN", "")
MOCK_INFERENCE = _bool(os.getenv("MOCK_INFERENCE"))
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
MAX_IMAGE_SIZE = _int(os.getenv("MAX_IMAGE_SIZE_MB", "10"), 10) * 1024 * 1024
MAX_VIDEO_SIZE = _int(os.getenv("MAX_VIDEO_SIZE_MB", "50"), 50) * 1024 * 1024
MAX_VIDEO_DURATION_S = _int(os.getenv("MAX_VIDEO_DURATION_S", "120"), 120)
FRAME_SAMPLE_INTERVAL = _int(os.getenv("FRAME_SAMPLE_INTERVAL", "30"), 30)
HOST = os.getenv("HOST", "0.0.0.0")
PORT = _int(os.getenv("PORT", "8000"), 8000)