# Ollama image adapted to run without root.
# Pinned to a stable release. Pinned by digest in step 8.
FROM ollama/ollama:0.40.18

# Dedicated unprivileged user with a fixed UID, and a models directory it owns.
# A new named volume mounted on /models inherits this ownership.
RUN useradd --uid 10001 --create-home --shell /usr/sbin/nologin ollama \
    && mkdir /models \
    && chown ollama:ollama /models

# Models live in /models (a volume), not in the user's home directory.
# The server listens on all interfaces of the container; only Docker networks reach it.
ENV OLLAMA_MODELS=/models \
    OLLAMA_HOST=0.0.0.0:11434 \
    HOME=/home/ollama

# Numeric UID: tools can check "not root" without reading /etc/passwd.
USER 10001
