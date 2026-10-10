#!/bin/bash
set -euo pipefail
set -x

my_dir=$(cd -- "$(dirname -- "$0")" && pwd)
cd "$my_dir"

# shellcheck disable=SC1091
source "$my_dir/weather.env"
export MIMIR_URL MIMIR_USER LOKI_URL LOKI_USER

## install crontab
crontab crontab.txt

HOST_IP=$(ip -4 addr show scope global dev docker0 | grep inet | awk '{print $2}' | cut -d / -f 1)
export HOST_IP
printf 'HOST_IP=%s\n' "$HOST_IP"
cmd=(up -d)
if (($# > 0)); then
  echo setting custom cmd
  cmd=("$@")
  printf 'cmd=%s\n' "${cmd[*]}"
fi

alloy_version=v1.16.0
if [[ "$(uname -m)" == "armv7l" ]]; then
  export ALLOY_IMAGE="weather-pi/alloy:armv7-${alloy_version}"
  if [[ ${cmd[0]} != "down" ]]; then
    local_platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}/{{.Variant}}' "$ALLOY_IMAGE" 2>/dev/null || true)
    if [[ $local_platform != "linux/arm/v7" ]]; then
      docker buildx build \
        --platform linux/arm/v7 \
        --load \
        --tag "$ALLOY_IMAGE" \
        --build-arg "ALLOY_VERSION=$alloy_version" \
        --file "$my_dir/Dockerfile.alloy-armv7" \
        "$my_dir"
    fi
  fi
else
  export ALLOY_IMAGE=grafana/alloy:latest
fi

docker-compose "${cmd[@]}"
