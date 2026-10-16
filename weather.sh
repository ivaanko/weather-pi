#!/bin/bash

set -euo pipefail

my_dir=$(cd -- "$(dirname -- "$0")" && pwd)

# shellcheck disable=SC1091,SC2154
source "$my_dir/weather.env"

# shellcheck disable=SC2154
weather=$(curl -fsS "http://api.openweathermap.org/data/2.5/weather?q=${location}&APPID=${OWM_KEY}&units=metric" | jq -r '[.main.temp, .main.humidity, .main.pressure, .wind.speed, .wind.deg, .main.feels_like] | @tsv')
IFS=$'\t' read -r out_celsius_temperature out_humidity_level out_pressure out_wind_speed out_wind_deg out_feels_like <<<"$weather"

## pushgateway
cat <<EOF | curl -sS --data-binary @- "http://localhost:9091/metrics/job/weather/instance/${HOSTNAME}/localisation/out/location/${location}"
# TYPE celsius_temperature gauge
celsius_temperature{job="weather"} $out_celsius_temperature
# TYPE feels_like gauge
feels_like{job="weather"} $out_feels_like
# TYPE humidity_level gauge
humidity_level{job="weather"} $out_humidity_level
# TYPE atm_pressure gauge
atm_pressure{job="weather"} $out_pressure
# TYPE wind_speed gauge
wind_speed{job="weather"} $out_wind_speed
# TYPE wind_dir gauge
wind_dir{job="weather"} $out_wind_deg
EOF

## Grafana Cloud annotation
curl -sS -X POST -H "Authorization: Bearer ${GRAFANA_TOKEN}" "${GRAFANA_URL}/api/annotations" -H "Content-Type: application/json" \
  --data @- <<EOF
  {
    "text": "stats updated",
    "tags": [
      "weather",
      "pi"
    ]
}
EOF
