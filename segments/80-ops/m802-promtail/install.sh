#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh 2>/dev/null || true; load_env 2>/dev/null || true
BIN_DIR="/usr/local/bin"; CONF="/etc/promtail/promtail.yml"
POS="${PROMTAIL_POSITIONS:-/var/lib/promtail/positions.yaml}"
mkdir -p /etc/promtail /var/lib/promtail /var/log/screen /var/log/tmux
if ! command -v promtail >/dev/null 2>&1; then
  ARCH=$(uname -m)
  URL="https://github.com/grafana/loki/releases/latest/download/promtail-linux-arm64.zip"
  [[ "$ARCH" =~ "armv7" ]] && URL="https://github.com/grafana/loki/releases/latest/download/promtail-linux-arm.zip"
  apt-get update -y && apt-get install -y unzip curl
  cd /tmp && curl -fsSLO "$URL" && unzip -o $(basename "$URL") -d "$BIN_DIR"
fi
cat >"$CONF" <<'YML'
server:
  http_listen_port: 9080
  grpc_listen_port: 0
positions:
  filename: ${POS}
clients:
  - url: ${LOKI_LOCAL_URL:-http://127.0.0.1:3100}/loki/api/v1/push
  - url: ${GRAFANA_URL:-https://example.grafana.net}/loki/api/v1/push
    basic_auth:
      username: "${GRAFANA_USER:-user}"
      password: "${GRAFANA_API_KEY:-}"

scrape_configs:
  - job_name: system
    static_configs:
      - targets: [localhost]
        labels:
          job: varlogs
          host: ${HOSTNAME}
          __path__: /var/log/*.log

  - job_name: journald
    journal:
      json: false
      path: /var/log/journal
      labels:
        job: systemd-journal
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'

  - job_name: screen_logs
    static_configs:
      - targets: [localhost]
        labels:
          job: screen
          host: ${HOSTNAME}
          __path__: /var/log/screen/*.log

  - job_name: tmux_logs
    static_configs:
      - targets: [localhost]
        labels:
          job: tmux
          host: ${HOSTNAME}
          __path__: /var/log/tmux/*.log
YML
cat >/etc/systemd/system/promtail.service <<'SVC'
[Unit]
Description=Promtail Service
After=network-online.target loki.service
Wants=network-online.target
[Service]
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail.yml
Restart=always
[Install]
WantedBy=multi-user.target
SVC
systemctl daemon-reload
systemctl enable --now promtail
