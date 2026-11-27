#!/bin/sh
# Runs only in the short-lived "models-pull" container: the ONLY container
# with Internet access. It downloads the models into the shared volume, then exits.
set -eu

# "ollama pull" is a client: it needs a local server to talk to.
ollama serve >/dev/null 2>&1 &
server_pid=$!

# Wait until the server answers, for 30 seconds at most.
i=0
until ollama list >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 30 ]; then
    echo "Ollama server did not start" >&2
    exit 1
  fi
  sleep 1
done

for model in "$CHAT_MODEL" "$EMBED_MODEL"; do
  echo "Pulling $model"
  ollama pull "$model"
done

# The ID column identifies the exact model version: record it (supply chain).
echo "Models now available:"
ollama list

kill "$server_pid"
