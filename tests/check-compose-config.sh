#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"

MIMIR_URL=https://mimir.invalid/push \
  MIMIR_USER=validation \
  LOKI_URL=https://loki.invalid/push \
  LOKI_USER=validation \
  docker compose -f docker-compose.yaml config --quiet
