#!/usr/bin/env bash
set -euo pipefail

# Validate TrailBase migrations by starting the server and checking for errors.
# On success: TrailBase stays running (ready for dev).
# On failure: prints SQL errors and exits non-zero.

TRAIL_PORT="${TRAIL_PORT:-4000}"
TRAIL_URL="http://localhost:${TRAIL_PORT}"
HEALTHCHECK_URL="${TRAIL_URL}/api/healthcheck"
LOG_FILE="/tmp/trail-migrate-$$.log"
TIMEOUT_SECS=15

# Kill any existing trail process on the port
if curl -sf "$HEALTHCHECK_URL" > /dev/null 2>&1; then
  echo "Stopping existing TrailBase on port ${TRAIL_PORT}..."
  EXISTING_PID=$(lsof -ti ":${TRAIL_PORT}" 2>/dev/null || true)
  if [ -n "$EXISTING_PID" ]; then
    kill "$EXISTING_PID" 2>/dev/null || true
    sleep 1
  fi
fi

echo "Starting TrailBase (applying migrations)..."
trail run --dev --runtime-root-fs traildepot > "$LOG_FILE" 2>&1 &
TRAIL_PID=$!

elapsed=0
while [ "$elapsed" -lt "$TIMEOUT_SECS" ]; do
  if ! kill -0 "$TRAIL_PID" 2>/dev/null; then
    echo ""
    echo "ERROR: Migration failed. TrailBase output:"
    echo "----------------------------------------"
    cat "$LOG_FILE"
    echo "----------------------------------------"
    rm -f "$LOG_FILE"
    exit 1
  fi

  if curl -sf "$HEALTHCHECK_URL" > /dev/null 2>&1; then
    echo "Migrations applied successfully. TrailBase running on port ${TRAIL_PORT} (PID ${TRAIL_PID})."
    rm -f "$LOG_FILE"
    exit 0
  fi

  sleep 0.5
  elapsed=$((elapsed + 1))
done

echo ""
echo "ERROR: TrailBase did not become healthy within ${TIMEOUT_SECS}s. Output:"
echo "----------------------------------------"
cat "$LOG_FILE"
echo "----------------------------------------"
kill "$TRAIL_PID" 2>/dev/null || true
rm -f "$LOG_FILE"
exit 1
