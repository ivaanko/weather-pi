#!/bin/bash
set -euo pipefail
set -x

my_dir=$(dirname $0)

source $my_dir/weather.env
sed -e "s#MIMIR_URL#${MIMIR_URL}#" prometheus.yaml.tpl > prometheus.yaml
sed -ie "s/MIMIR_USER/${MIMIR_USER}/" prometheus.yaml
sed -e "s#LOKI_URL#${LOKI_URL}#" promtail.yaml.tpl > promtail.yaml
sed -ie "s/LOKI_USER/${LOKI_USER}/" promtail.yaml

## install crontab
crontab crontab.txt

cmd='up -d'
if [ "${1:-''}" != "''" ] ; then
  echo setting custom cmd
  cmd="$@"
  echo "cmd=$cmd"
fi
docker-compose $cmd
