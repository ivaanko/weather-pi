# weather-pi

Send DHT22 sensor and [OpenWeatherMap API](https://openweathermap.org/api) data to [Grafana Cloud](https://grafana.com/) as well as Pi logs and node-exporter metrics.

Prerequisites:

Raspberry Pi with DHT22 sensor and any Linux distribution, Docker, docker-compose, curl, jq, OpenWeatherMap API subscription (can be free), Grafana Cloud membership (can be free) or self-hosted Grafana and Prometheus (to be configured in `weather.env` file).

Installation:

Clone into $HOME (or update crontab.txt for alernative path)

Add required files:
* `grafana-cloud-key.txt`
* `weather.env` (see [weather.env.example](weather.env.example))

Spin up: `./runme.sh`

Strip down: `./runme.sh down -v` and edit crontab if you want to stop OpenWeatherMap queries too.

Feel free to import [Grafana dashboard](dashboard.json) to your Grafana instance.
![image](https://github.com/ivaanko/weather-pi/assets/1969105/5a767a04-f28d-41de-b188-2bf68a7dc9f8)
