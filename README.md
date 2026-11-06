# weather-pi

Collects temperature and humidity from a DHT22 sensor and current weather from OpenWeatherMap. Prometheus sends metrics to Grafana Cloud (or a compatible Prometheus remote-write endpoint), and Promtail sends Pi and container logs to Loki.

## Requirements

- Raspberry Pi running Linux, with a DHT22 connected and supported by the `sfudeus/dht22-exporter` image
- Docker Engine with Docker Compose (`docker compose`) or the standalone `docker-compose` command
- `bash`, `curl`, `jq`, and `crontab` on the host
- OpenWeatherMap API key
- Grafana Cloud credentials for metrics and logs, or compatible self-hosted Mimir/Prometheus and Loki endpoints

## Setup

1. Clone this repository into a persistent directory. The cron job uses that path directly.
2. Copy `weather.env.example` to `weather.env` and set the OpenWeatherMap key, location, metrics endpoint and username, and logs endpoint and username. Set `GRAFANA_URL` and `GRAFANA_TOKEN` together if you want weather update annotations.
3. Put the Grafana Cloud access policy token in `grafana-cloud-key.txt`. It must be readable by Docker and should have the required metrics-write and logs-write permissions.
4. Start the services with `./runme.sh`. This generates the Prometheus and Promtail configuration files, adds or updates a marked five-minute weather collection entry in your existing crontab, and starts the Compose services.
5. Import `dashboard.json` into Grafana. If your data source UIDs differ from the dashboard defaults, update them in the imported dashboard.

`weather.env` is sourced as a Bash file, so quote values containing spaces or shell-special characters. Keep both `weather.env` and `grafana-cloud-key.txt` private; they are excluded from git.

To stop the containers, run `./runme.sh down`. To also remove the Prometheus data volume, run `./runme.sh down -v`. Remove the `weather-pi` marked block from your crontab if you no longer want scheduled API requests.

The weather collector requires the Pushgateway service on `localhost:9091`. API failures are logged to `weather.log` in the clone directory and do not publish a partial sample. A Grafana annotation failure is also reported, after metrics have been sent to Pushgateway.
