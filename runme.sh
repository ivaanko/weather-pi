#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
env_file="$script_dir/weather.env"

if [[ ! -r "$env_file" ]]; then
  echo "Missing $env_file; copy weather.env.example to weather.env and configure it." >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$env_file"

for name in MIMIR_URL MIMIR_USER LOKI_URL LOKI_USER; do
  if [[ -z "${!name:-}" ]]; then
    echo "Set $name in weather.env." >&2
    exit 1
  fi
done

escape_sed_replacement() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//&/\\&}
  value=${value//|/\\|}
  printf '%s' "$value"
}

sed \
  -e "s|MIMIR_URL|$(escape_sed_replacement "$MIMIR_URL")|g" \
  -e "s|MIMIR_USER|$(escape_sed_replacement "$MIMIR_USER")|g" \
  "$script_dir/prometheus.yaml.tpl" > "$script_dir/prometheus.yaml"
sed \
  -e "s|LOKI_URL|$(escape_sed_replacement "$LOKI_URL")|g" \
  -e "s|LOKI_USER|$(escape_sed_replacement "$LOKI_USER")|g" \
  "$script_dir/promtail.yaml.tpl" > "$script_dir/promtail.yaml"

if [[ ${1:-up} != down* ]]; then
  cron_file=$(mktemp)
  merged_cron=$(mktemp)
  trap 'rm -f "$cron_file" "$merged_cron"' EXIT
  sed "s|WEATHER_PI_DIR|$(escape_sed_replacement "$script_dir")|g" "$script_dir/crontab.txt" > "$cron_file"
  (crontab -l 2>/dev/null || true) | awk '
    /^# BEGIN weather-pi$/ { skip=1; next }
    /^# END weather-pi$/ { skip=0; next }
    index($0, "$HOME/weather-pi/weather.sh") { next }
    !skip { print }
  ' > "$merged_cron"
  cat "$cron_file" >> "$merged_cron"
  crontab "$merged_cron"
fi

if docker compose version >/dev/null 2>&1; then
  compose=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  compose=(docker-compose)
else
  echo "Docker Compose is required (docker compose or docker-compose)." >&2
  exit 1
fi

cd "$script_dir"
if (($#)); then
  "${compose[@]}" -f docker-compose.yaml "$@"
else
  "${compose[@]}" -f docker-compose.yaml up -d
fi
