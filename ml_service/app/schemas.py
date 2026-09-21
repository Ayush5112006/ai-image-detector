"""Pydantic response models — also generate the OpenAPI schema."""
from typing import Literal, Optional

from pydantic import BaseModel, Field

PredictionVerdict = Literal["AI", "Real"]


class PredictionData(BaseModel):
    verdict: PredictionVerdict = Field(
        ...,
        description="Final classification: AI-generated or Real/human-made.",
    )
    confidence: float = Field(
        ...,
        ge=0,
        le=100,
        description="Confidence percentage of the verdict.",
    )
    label: str = Field(..., description="Human readable class label.")
    modelName: str = Field(..., description="Model id used for inference.")
    processingMs: int = Field(0, description="Inference time in milliseconds.")
    framesAnalyzed: Optional[int] = Field(
        None, description="For video input, number of frames analyzed."
    )


class PredictionResponse(BaseModel):
    success: bool = True
    message: str = "Prediction completed."
    data: PredictionData


class ApiError(BaseModel):
    success: bool = False
    message: str
    error: dict


class HealthResponse(BaseModel):
    status: Literal["ok"]
    model: str
    mock: bool
    version: str = "1.0.0"