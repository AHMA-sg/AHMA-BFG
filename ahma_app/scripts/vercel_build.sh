#!/usr/bin/env bash
set -euo pipefail

FLUTTER_BIN="./flutter/bin/flutter"
if [ ! -x "$FLUTTER_BIN" ]; then
  FLUTTER_BIN="flutter"
fi

"$FLUTTER_BIN" build web --release \
  --dart-define="BACKEND_API_URL=${BACKEND_API_URL:-http://localhost:5001}" \
  --dart-define="BACKEND_API_KEY=${BACKEND_API_KEY:-}" \
  --dart-define="ULTRAVOX_API_KEY=${ULTRAVOX_API_KEY:-}" \
  --dart-define="ULTRAVOX_BASE_URL=${ULTRAVOX_BASE_URL:-https://api.ultravox.ai/api}" \
  --dart-define="CORPUS_ID_CAREGIVER_GUIDES=${CORPUS_ID_CAREGIVER_GUIDES:-}" \
  --dart-define="AHMA_AGENT_ID=${AHMA_AGENT_ID:-}" \
  --dart-define="WEBHOOK_SECRET=${WEBHOOK_SECRET:-default_secret}" \
  --dart-define="WEBHOOK_PORT=${WEBHOOK_PORT:-8080}"
