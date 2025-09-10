#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

# Installera beroenden för healthcheck-verktyget
sudo apt-get update -y
sudo apt-get install -y dnsutils lsof

# Systemd-service + timer för periodic healthcheck
INT="${HEALTHCHECK_INTERVAL_MINUTES:-5}"
sudo tee /etc/systemd/system/${REPO_NAME}-health.service >/dev/null <<EOF
[Unit]
Description=${REPO_NAME} periodic health check
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -lc '${ROOT_DIR}/tools/healthcheck.sh'
EOF

sudo tee /etc/systemd/system/${REPO_NAME}-health.timer >/dev/null <<EOF
[Unit]
Description=Run ${REPO_NAME} healthcheck every ${INT} minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=${INT}min
Unit=${REPO_NAME}-health.service
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ${REPO_NAME}-health.timer
log "[05-monitor] timer aktiv var ${INT} min"
