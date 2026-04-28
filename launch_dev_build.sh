#!/usr/bin/env bash
# Start Postgres (Docker), migrate, run the API, build and launch the Solo macOS app.
# When the app quits, the API and Docker services are stopped.
# Logs from the API and xcodebuild are printed to this terminal.
#
# Usage (repo root):
#   ./launch_dev_build.sh              full flow (default)
#   ./launch_dev_build.sh --api-only  Docker + migrate + API only (foreground; same as former start-api-stack)
#   npm run start:stack               API-only (runs --api-only)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

API_ONLY=0
if [[ "${1:-}" == "--api-only" ]]; then
  API_ONLY=1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop (or the Docker daemon), then try again." >&2
  exit 1
fi

echo "Starting PostgreSQL (docker compose)…"
docker compose up -d postgres

echo "Waiting for Postgres to accept connections…"
ready=0
for _ in $(seq 1 40); do
  if docker compose exec -T postgres pg_isready -U solodev -d solo >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.5
done

if [ "$ready" -ne 1 ]; then
  echo "Postgres did not become ready in time. Check: docker compose logs postgres" >&2
  exit 1
fi

echo "Applying database migrations…"
cd "$ROOT/backend" || exit 1
node <<'NODE'
const path = require("path");
const { execSync } = require("child_process");
require("dotenv").config({ path: path.resolve(process.cwd(), "..", ".env") });
execSync("npx prisma migrate deploy", { stdio: "inherit", env: process.env });
NODE
cd "$ROOT"

if [[ "$API_ONLY" -eq 1 ]]; then
  echo "Postgres is ready. Building and starting API (foreground)…"
  exec npm run start:api
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode command-line tools, then try again." >&2
  exit 1
fi

XCODE_PROJ="${ROOT}/frontend/Solo.xcodeproj"
if [[ ! -d "$XCODE_PROJ" ]]; then
  echo "Expected Xcode project at: $XCODE_PROJ" >&2
  exit 1
fi

cleanup() {
  set +e
  echo "" >&2
  echo "Tearing down dev session…" >&2
  if [[ -n "${BACKEND_PID:-}" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    echo "Stopping API (pid $BACKEND_PID)…" >&2
    kill -TERM "$BACKEND_PID" 2>/dev/null
    # Give Node a moment to release the port; ignore wait errors if already dead.
    wait "$BACKEND_PID" 2>/dev/null
  fi
  echo "Stopping Docker services…" >&2
  (cd "$ROOT" && docker compose down) >&2
  echo "Done." >&2
}

echo "Building backend…"
npm run build --prefix backend

echo "Starting API (background; logs follow on this terminal)…"
cd "$ROOT/backend" && node dist/index.js &
BACKEND_PID=$!
cd "$ROOT"

trap cleanup EXIT INT TERM HUP

# Fail fast if the server process did not stay up.
sleep 0.2
if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
  echo "API process exited immediately. Check your .env and backend logs above." >&2
  exit 1
fi

DERIVED="${ROOT}/frontend/.derivedData"
echo "Building Solo (xcodebuild)…"
xcodebuild \
  -project "$XCODE_PROJ" \
  -scheme Solo \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED" \
  build

APP_PATH="${DERIVED}/Build/Products/Debug/Solo.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: expected app bundle at: $APP_PATH" >&2
  exit 1
fi

echo "Launching Solo. Close the app to stop the API and Docker. (Ctrl+C also tears down.)"
open -W -n "$APP_PATH"

# Normal quit: open returned; EXIT trap runs cleanup.
