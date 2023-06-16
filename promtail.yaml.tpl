server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: LOKI_URL
    basic_auth:
      username: LOKI_USER
      password_file: /grafana-cloud/key

scrape_configs:
- job_name: pi-system
  static_configs:
  - targets:
      - localhost
    labels:
      job: pi-varlogs
      __path__: /var/log/*log
- job_name: pi-containers
  static_configs:
  - targets:
      - localhost
    labels:
      job: pi-containerlogs
      __path__: /var/lib/docker/containers/*/*log

  pipeline_stages:
  - json:
      expressions:
        output: log
        stream: stream
        attrs:
  - json:
      expressions:
        tag:
      source: attrs
  - regex:
      expression: (?P<container_name>(?:[^|]*[^|]))
      source: tag
  - timestamp:
      format: RFC3339Nano
      source: time
  - labels:
      # tag:
      stream:
      container_name:
  - output:
      source: output

