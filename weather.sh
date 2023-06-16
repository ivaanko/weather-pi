#!/bin/bash

set -euo pipefail

my_dir=$(dirname $0)

source $my_dir/weather.env

weather=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=${location}&APPID=${OWM_KEY}&units=metric" | jq '.main.temp,.main.humidity,.main.pressure,.wind.speed,.wind.deg,.main.feels_like')
out_celsius_temperature=$(echo $weather | cut -d " " -f1)
out_humidity_level=$(echo $weather | cut -d " " -f2)
out_pressure=$(echo $weather | cut -d " " -f3)
out_wind_speed=$(echo $weather | cut -d " " -f4)
out_wind_deg=$(echo $weather | cut -d " " -f5)
out_feels_like=$(echo $weather | cut -d " " -f6)

## pushgateway
cat <<EOF | curl -sS --data-binary @- http://localhost:9091/metrics/job/weather/instance/$HOSTNAME/localisation/out/location/$location
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
curl -sS -X POST -H "Authorization: Bearer ${GRAFANA_TOKEN}" ${GRAFANA_URL}/api/annotations -H "Content-Type: application/json"  \
--data @- << EOF
  {
    "text": "stats updated",
    "tags": [
      "weather",
      "pi"
    ]
}
EOF

