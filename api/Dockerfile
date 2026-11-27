# VERIFY: Python version and tag on Docker Hub (python). Pinned by digest in step 8.
ARG PYTHON_IMAGE=python:3.13-slim

# ---- Stage 1: install dependencies (pip and build tools stay in this stage) ----
FROM ${PYTHON_IMAGE} AS builder
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /opt/venv
COPY requirements.txt .
# --require-hashes: any package whose hash differs from requirements.txt is rejected.
RUN /opt/venv/bin/pip install --require-hashes -r requirements.txt

# ---- Stage 2: runtime image (only the virtualenv and the code) ----
FROM ${PYTHON_IMAGE}
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN useradd --uid 10002 --no-create-home --shell /usr/sbin/nologin api
COPY --from=builder /opt/venv /opt/venv
WORKDIR /srv
# Files stay owned by root: the api user can read the code but not modify it.
COPY app ./app
USER 10002
EXPOSE 8000
# --no-access-log: our middleware logs requests as JSON.
# VERIFY: --no-server-header (hides the "server: uvicorn" banner) in `uvicorn --help`.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log", "--no-server-header"]
