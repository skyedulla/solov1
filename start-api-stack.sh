#!/usr/bin/env bash
# Start local Postgres (Docker) then build and run the Express API.
# Usage from repo root: ./start-api-stack.sh   or   npm run start:stack
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

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

echo "Postgres is ready. Building and starting API…"
exec npm run start:api
