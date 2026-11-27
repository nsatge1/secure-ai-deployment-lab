"""Entry point of the RAG API."""

import logging
import re
import time
import uuid

from fastapi import FastAPI, Request, Response

from app.config import get_settings
from app.log_config import setup_logging

settings = get_settings()
setup_logging(settings.log_level)
logger = logging.getLogger("app")

# Interactive docs and the OpenAPI schema are disabled: they would map the whole API for an attacker.
app = FastAPI(title="Secure RAG API", docs_url=None, redoc_url=None, openapi_url=None)

# An incoming request ID is reused only if it is short and contains safe characters.
_REQUEST_ID = re.compile(r"[A-Za-z0-9-]{1,64}")


@app.middleware("http")
async def log_requests(request: Request, call_next) -> Response:
    incoming = request.headers.get("x-request-id", "")
    request_id = incoming if _REQUEST_ID.fullmatch(incoming) else str(uuid.uuid4())
    start = time.perf_counter()

    response = await call_next(request)

    response.headers["X-Request-ID"] = request_id
    # Metadata only: never the body, query string or headers (they can hold secrets or personal data).
    logger.info(
        "request",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status": response.status_code,
            "duration_ms": round((time.perf_counter() - start) * 1000, 1),
        },
    )
    return response


@app.get("/health")
def health() -> dict[str, str]:
    """Liveness check: the process answers. Dependencies are checked in later steps."""
    return {"status": "ok"}
