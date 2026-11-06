#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
env_file="$script_dir/weather.env"

if [[ ! -r "$env_file" ]]; then
  echo "Missing $env_file; copy weather.env.example to weather.env and configure it." >&2
  exit 1
fi
# weather.env is a shell file; keep it private because it contains API tokens.
# shellcheck disable=SC1090
source "$env_file"

: "${OWM_KEY:?Set OWM_KEY in weather.env}"
: "${location:?Set location in weather.env}"

for command in curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

weather_json=$(curl --fail --silent --show-error --get \
  --data-urlencode "q=$location" \
  --data-urlencode "appid=$OWM_KEY" \
  --data-urlencode "units=metric" \
  'https://api.openweathermap.org/data/2.5/weather')

if ! jq -e '.cod == 200' >/dev/null <<<"$weather_json"; then
  echo "OpenWeatherMap returned an unsuccessful response: $(jq -r '.message // "unknown error"' <<<"$weather_json")" >&2
  exit 1
fi

# jq validates that every value is present and numeric before anything is sent.
readarray -t values < <(jq -er '
  [.main.temp, .main.humidity, .main.pressure, .wind.speed, .wind.deg, .main.feels_like]
  | if all(.[]; type == "number") then .[] else error("missing or non-numeric weather field") end
' <<<"$weather_json")
if (( ${#values[@]} != 6 )); then
  echo "OpenWeatherMap response did not contain all expected numeric weather fields." >&2
  exit 1
fi

host=${HOSTNAME:-$(hostname)}
host_path=$(jq -rn --arg value "$host" '$value|@uri')
location_path=$(jq -rn --arg value "$location" '$value|@uri')
cat <<EOF | curl --fail --silent --show-error --data-binary @- \
  "http://localhost:9091/metrics/job/weather/instance/$host_path/localisation/out/location/$location_path"
# TYPE celsius_temperature gauge
celsius_temperature{job="weather"} ${values[0]}
# TYPE feels_like gauge
feels_like{job="weather"} ${values[5]}
# TYPE humidity_level gauge
humidity_level{job="weather"} ${values[1]}
# TYPE atm_pressure gauge
atm_pressure{job="weather"} ${values[2]}
# TYPE wind_speed gauge
wind_speed{job="weather"} ${values[3]}
# TYPE wind_dir gauge
wind_dir{job="weather"} ${values[4]}
EOF

# Annotations are optional; metrics collection still works without Grafana credentials.
if [[ -n "${GRAFANA_URL:-}" || -n "${GRAFANA_TOKEN:-}" ]]; then
  : "${GRAFANA_URL:?Set GRAFANA_URL when GRAFANA_TOKEN is configured}"
  : "${GRAFANA_TOKEN:?Set GRAFANA_TOKEN when GRAFANA_URL is configured}"
  curl --fail --silent --show-error -X POST \
    -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    -H 'Content-Type: application/json' \
    --data '{"text":"stats updated","tags":["weather","pi"]}' \
    "${GRAFANA_URL%/}/api/annotations" >/dev/null
fi
