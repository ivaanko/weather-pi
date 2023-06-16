# my global config
global:
  #scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  #evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).
  external_labels:
    host: 'pi'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
  - job_name: 'node'
    static_configs:
    - targets:
      - 'localhost:9100'
  - job_name: 'docker'
    static_configs:
    - targets:
      - 'localhost:9323'
  - job_name: 'pushgateway'
    static_configs:
    - targets: ['localhost:9091']
  - job_name: 'dht22'
    static_configs:
      - targets: ['localhost:8080']
remote_write:
  - url: MIMIR_URL
    basic_auth:
      username: MIMIR_USER
      password_file: /grafana-cloud/key

