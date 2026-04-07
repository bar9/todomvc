#!/usr/bin/env bash
set -euo pipefail

# Run Hurl API integration tests against TrailBase.
# Resets the DB, starts TrailBase, runs all .hurl files, then cleans up.

TRAIL_PORT="${TRAIL_PORT:-4000}"
TRAIL_URL="http://localhost:${TRAIL_PORT}"
VARS="tests/api/vars.env"
DB_DIR="traildepot/data"
REPORT_DIR="test-results"
TRAIL_PID=""

cleanup() {
  if [ -n "$TRAIL_PID" ] && kill -0 "$TRAIL_PID" 2>/dev/null; then
    kill "$TRAIL_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# --- Stop any existing TrailBase on the port ---
if curl -sf "${TRAIL_URL}/api/healthcheck" > /dev/null 2>&1; then
  echo "Stopping existing TrailBase on port ${TRAIL_PORT}..."
  EXISTING_PID=$(lsof -ti ":${TRAIL_PORT}" 2>/dev/null || true)
  if [ -n "$EXISTING_PID" ]; then
    kill "$EXISTING_PID" 2>/dev/null || true
    sleep 1
  fi
fi

# --- Reset DB ---
echo "Resetting database..."
rm -f "$DB_DIR/main.db" "$DB_DIR/main.db-wal" "$DB_DIR/main.db-shm"

# --- Start TrailBase ---
echo "Starting TrailBase (applying migrations)..."
trail run --dev --runtime-root-fs traildepot > /tmp/trail-test-$$.log 2>&1 &
TRAIL_PID=$!

TIMEOUT_SECS=15
elapsed=0
while [ "$elapsed" -lt "$TIMEOUT_SECS" ]; do
  if ! kill -0 "$TRAIL_PID" 2>/dev/null; then
    echo "ERROR: TrailBase crashed during startup:"
    cat /tmp/trail-test-$$.log
    exit 1
  fi
  if curl -sf "${TRAIL_URL}/api/healthcheck" > /dev/null 2>&1; then
    echo "TrailBase ready on port ${TRAIL_PORT} (PID ${TRAIL_PID})."
    break
  fi
  sleep 0.5
  elapsed=$((elapsed + 1))
done

if [ "$elapsed" -ge "$TIMEOUT_SECS" ]; then
  echo "ERROR: TrailBase did not start within ${TIMEOUT_SECS}s:"
  cat /tmp/trail-test-$$.log
  exit 1
fi

# --- Run Hurl tests ---
mkdir -p "$REPORT_DIR"
echo ""
echo "=== Running Hurl tests ==="
hurl --test --error-format long \
  --report-junit "$REPORT_DIR/results.xml" \
  --variables-file "$VARS" \
  tests/api/*.hurl

echo ""
echo "=== All tests passed ==="
