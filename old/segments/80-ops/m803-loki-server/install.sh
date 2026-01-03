#!/usr/bin/env bash
set -euo pipefail
BIN_DIR="/usr/local/bin"; CONF_DIR="/etc/loki"; DATA_DIR="/var/lib/loki"
mkdir -p "$CONF_DIR" "$DATA_DIR/chunks" "$DATA_DIR/rules"
ARCH=$(uname -m)
URL="https://github.com/grafana/loki/releases/latest/download/loki-linux-arm64.zip"
[[ "$ARCH" =~ "armv7" ]] && URL="https://github.com/grafana/loki/releases/latest/download/loki-linux-arm.zip"
apt-get update -y && apt-get install -y unzip curl
cd /tmp && curl -fsSLO "$URL" && unzip -o $(basename "$URL") -d "$BIN_DIR"
install -m 644 "$(dirname "$0")/loki-config.yml" "$CONF_DIR/config.yml"
cat >/etc/systemd/system/loki.service <<'SVC'
[Unit]
Description=Loki Log Aggregator
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/config.yml
Restart=always
[Install]
WantedBy=multi-user.target
SVC
systemctl daemon-reload
systemctl enable --now loki
