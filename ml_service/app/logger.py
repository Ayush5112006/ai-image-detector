"""Structured logger for the ML service.

Logged events carry structured metadata (request id, media type, duration)
but never file contents or credentials.
"""
import json
import logging
import sys

from .config import LOG_LEVEL

_LOG_FORMAT = "%(asctime)s %(message)s"


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S.%fZ"),
            "level": record.levelname.lower(),
            "logger": record.name,
            "message": record.getMessage(),
        }
        extra = getattr(record, "meta", None)
        if isinstance(extra, dict):
            payload.update(extra)
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload)


def get_logger(name="ml_service"):
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger
    logger.setLevel(LOG_LEVEL)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logger.addHandler(handler)
    logger.propagate = False
    return logger


def log_meta(logger, record, message, meta=None):
    logger.log(record, message, extra={"meta": meta or {}})