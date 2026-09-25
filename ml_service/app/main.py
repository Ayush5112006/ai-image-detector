"""ChitraVision ML Service — FastAPI entrypoint.

Runs a HuggingFace ViT image-classification model (AI-generated image
detection) behind a small REST API used by the Node.js backend.
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from .config import MOCK_INFERENCE, MODEL_ID
from .logger import get_logger
from .model import get_predictor
from .predict import router as predict_router

logger = get_logger("ml_service.main")


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Load the model once when the server starts (skipped in mock mode).
    # Requests reuse the process-wide singleton — no per-request downloads.
    get_predictor().load()
    yield


app = FastAPI(
    title="ChitraVision ML Service",
    description=(
        "Deepfake / AI-generated content detection using "
        "`manishpandey68/detection-of-ai-generated-images-through-ViT`."
    ),
    version="2.0.0",
    docs_url="/docs",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(RequestValidationError)
async def validation_handler(_request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "message": "Invalid request parameters.",
            "error": {
                "code": "VALIDATION_ERROR",
                "details": exc.errors(),
            },
        },
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(_request: Request, exc: StarletteHTTPException):
    detail = exc.detail
    if isinstance(detail, dict):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "message": detail.get("message", "Request failed."),
                "error": detail.get("error", {"code": "HTTP_ERROR"}),
            },
        )
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "message": str(detail),
            "error": {"code": "HTTP_ERROR"},
        },
    )


@app.exception_handler(Exception)
async def unhandled_handler(_request: Request, exc: Exception):
    logger.error("unhandled error", {"errorMessage": str(exc), "errorType": type(exc).__name__})
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "An unexpected error occurred.",
            "error": {"code": "INTERNAL_ERROR"},
        },
    )


@app.get("/")
def root():
    return {"service": "chitravision-ml", "docs": "/docs", "openapi": "/openapi.json"}


app.include_router(predict_router)

# Attach structured request logging via middleware after routes are defined.
@app.middleware("http")
async def request_logging(request: Request, call_next):
    started = __import__("time").perf_counter()
    response = await call_next(request)
    duration_ms = int((__import__("time").perf_counter() - started) * 1000)
    logger.info(
        "request completed",
        {
            "method": request.method,
            "path": request.url.path,
            "status": response.status_code,
            "durationMs": duration_ms,
        },
    )
    return response


__all__ = ["app", "MOCK_INFERENCE", "MODEL_ID"]