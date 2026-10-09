# weather-pi

Send DHT22 sensor and [OpenWeatherMap API](https://openweathermap.org/api) data to [Grafana Cloud](https://grafana.com/) as well as Pi logs and exporter metrics, using Grafana Alloy for scraping and log shipping.

Prerequisites:

Raspberry Pi with DHT22 sensor and any Linux distribution, Docker, docker-compose, curl, jq, OpenWeatherMap API subscription (can be free), and Grafana Cloud (can be free) or self-hosted Mimir-compatible metrics and Loki endpoints configured in `weather.env`.

Installation:

Clone into $HOME (or update crontab.txt for alernative path)

Add required files:
* `grafana-cloud-key.txt`
* `weather.env` (see [weather.env.example](weather.env.example))

Spin up: `./runme.sh`

Check container platform support: `bash tests/check-alloy-platform.sh`. It verifies the ARMv7 build bases and upstream ARM64 image against registry manifests. It needs the Docker CLI, `jq`, and Docker Hub access; authenticate with `docker login` if anonymous rate limits are reached. The Docker daemon does not need to be running.

On 32-bit ARMv7 Raspberry Pi OS, `./runme.sh` builds a local Alloy `v1.16.0` image from upstream source the first time it is needed. This source build is resource-intensive and may take a long time on a Pi 3B+; ensure Docker has several gigabytes of free storage and sufficient memory or swap. On ARM64 and other systems, the upstream `grafana/alloy:latest` image is used.

Strip down: `./runme.sh down -v` and edit crontab if you want to stop OpenWeatherMap queries too. Alloy keeps its scrape WAL and log positions in the `alloy-data` volume; `down -v` removes that data.

Feel free to import [Grafana dashboard](dashboard.json) to your Grafana instance.
![image](https://github.com/ivaanko/weather-pi/assets/1969105/5a767a04-f28d-41de-b188-2bf68a7dc9f8)
