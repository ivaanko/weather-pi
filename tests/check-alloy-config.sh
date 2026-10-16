#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

docker run --rm \
  -v "$repo_dir/alloy.alloy:/etc/alloy/config.alloy:ro" \
  -e MIMIR_URL=https://mimir.invalid/push \
  -e MIMIR_USER=validation \
  -e LOKI_URL=https://loki.invalid/push \
  -e LOKI_USER=validation \
  grafana/alloy:v1.16.0 fmt --test /etc/alloy/config.alloy

docker run --rm \
  -v "$repo_dir/alloy.alloy:/etc/alloy/config.alloy:ro" \
  -e MIMIR_URL=https://mimir.invalid/push \
  -e MIMIR_USER=validation \
  -e LOKI_URL=https://loki.invalid/push \
  -e LOKI_USER=validation \
  grafana/alloy:v1.16.0 validate /etc/alloy/config.alloy
