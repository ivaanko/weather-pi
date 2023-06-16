# weather-pi

Send DHT22 sensor and [OpenWeatherMap API](https://openweathermap.org/api) data to [Grafana Cloud](https://grafana.com/) as well as Pi logs and node-exporter metrics.

Required files:
* `grafana-cloud-key.txt`
* `weather.env` (see [weather.env.example](weather.env.example))

Spin up: `./runme.sh`

Strip down: `./runme.sh down -v`
