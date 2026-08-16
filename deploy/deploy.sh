#!/usr/bin/env bash
# Roll the deployment forward to the latest published images.
# Run from the directory containing docker-compose.yml (e.g. /opt/quappe).
set -euo pipefail

cd "$(dirname "$0")"

echo "→ pulling latest images…"
docker compose pull

echo "→ (re)starting…"
docker compose up -d

echo "→ status:"
docker compose ps

echo "✓ done. Tail logs with: docker compose logs -f"
