"""API tests for the ML service. Run with:

    MOCK_INFERENCE=1 pytest tests/ -v

The heavy torch/transformers dependencies are not imported in mock mode,
so this suite exercises the validation, error handling and response
contract without downloading model weights.
"""
import io
import os

os.environ.setdefault("MOCK_INFERENCE", "1")

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from app.main import app

client = TestClient(app)


def _png_bytes(size=(32, 32)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", size, (120, 30, 200)).save(buf, format="PNG")
    return buf.getvalue()


def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    body = res.json()
    assert body["status"] == "ok"
    assert body["mock"] is True


def test_predict_image_valid():
    res = client.post(
        "/predict/image",
        files={"file": ("sample.png", _png_bytes(), "image/png")},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["success"] is True
    assert body["data"]["verdict"] in {"AI", "Real"}
    assert 0 <= body["data"]["confidence"] <= 100
    assert body["data"]["modelName"] == "mock-inference"


def test_predict_image_missing_file():
    res = client.post("/predict/image")
    assert res.status_code == 422


def test_predict_image_not_an_image():
    res = client.post(
        "/predict/image",
        files={"file": ("notes.txt", b"this is text", "text/plain")},
    )
    body = res.json()
    assert body["success"] is False
    assert body["error"]["code"] == "INVALID_FILE_TYPE"


def test_predict_image_corrupted_bytes():
    res = client.post(
        "/predict/image",
        files={"file": ("broken.png", b"\xff\xd8\xff\xe0corrupted", "image/png")},
    )
    body = res.json()
    assert body["success"] is False
    assert body["error"]["code"] in {"INVALID_IMAGE", "CORRUPTED_IMAGE"}


def test_predict_image_empty_file():
    res = client.post(
        "/predict/image",
        files={"file": ("empty.png", b"", "image/png")},
    )
    assert res.status_code == 422
    assert res.json()["error"]["code"] == "EMPTY_FILE"


@pytest.mark.parametrize("path", ["/predict/image", "/predict/video"])
def test_openapi_lists_endpoints(path):
    schema = client.get("/openapi.json").json()
    assert path in schema["paths"]


def test_validate_validation_error_envelope():
    # Malformed body (no multipart) triggers FastAPI validation handler.
    res = client.post("/predict/image", data="x")
    assert res.status_code == 422
    assert res.json()["success"] is False