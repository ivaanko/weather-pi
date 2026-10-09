#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"

if ! grep -Fq 'image: "${ALLOY_IMAGE:-grafana/alloy:latest}"' docker-compose.yaml; then
  printf 'FAIL: Compose does not allow selecting the Alloy image\n' >&2
  exit 1
fi

if ! grep -Fq 'weather-pi/alloy:armv7-' runme.sh || ! grep -Fq -- '--platform linux/arm/v7' runme.sh; then
  printf 'FAIL: runme.sh does not select and build a local ARMv7 image\n' >&2
  exit 1
fi

if ! grep -Fq 'export ALLOY_IMAGE=grafana/alloy:latest' runme.sh; then
  printf 'FAIL: runme.sh does not retain the upstream image for other platforms\n' >&2
  exit 1
fi

if ! grep -Fq 'CGO_ENABLED=0 GO_TAGS=' Dockerfile.alloy-armv7 || ! grep -Fq 'GOARM="${TARGETVARIANT#v}"' Dockerfile.alloy-armv7; then
  printf 'FAIL: ARMv7 build does not configure pure-Go ARM target compilation\n' >&2
  exit 1
fi

build_images=$(sed -nE 's/^FROM([[:space:]]+--platform=\$BUILDPLATFORM)?[[:space:]]+([^[:space:]]+:[^[:space:]]+).*/\2/p' Dockerfile.alloy-armv7 | sort -u)
if [[ -z $build_images ]]; then
  printf 'FAIL: no build image references found in Dockerfile.alloy-armv7\n' >&2
  exit 1
fi

while IFS= read -r image; do
  manifest=$(docker manifest inspect --verbose "$image")
  if ! jq -e 'any(.[]; .Descriptor.platform.os == "linux" and .Descriptor.platform.architecture == "arm" and .Descriptor.platform.variant == "v7")' <<<"$manifest" >/dev/null; then
    printf 'FAIL: build base %s does not publish linux/arm/v7\n' "$image" >&2
    exit 1
  fi
  printf 'PASS: %s publishes linux/arm/v7\n' "$image"
done <<<"$build_images"

manifest=$(docker manifest inspect --verbose grafana/alloy:latest)
if ! jq -e 'any(.[]; .Descriptor.platform.os == "linux" and .Descriptor.platform.architecture == "arm64")' <<<"$manifest" >/dev/null; then
  printf 'FAIL: grafana/alloy:latest does not publish linux/arm64\n' >&2
  exit 1
fi
printf 'PASS: grafana/alloy:latest publishes linux/arm64\n'
