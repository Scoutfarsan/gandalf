#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

sudo install -d -m 0755 /opt/${REPO_NAME}/tools
sudo install -m 0755 -o root -g root "$ROOT_DIR/tools/autoheal.sh" /opt/${REPO_NAME}/tools/autoheal.sh

INT="${AUTOHEAL_INTERVAL_MINUTES:-10}"
sudo tee /etc/systemd/system/autoheal.service >/dev/null <<EOF
[Unit]
Description=${REPO_NAME} Auto-Heal
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=/bin/bash -lc '/opt/${REPO_NAME}/tools/autoheal.sh'
EOF

sudo tee /etc/systemd/system/autoheal.timer >/dev/null <<EOF
[Unit]
Description=Auto-Heal every ${INT} minutes
[Timer]
OnBootSec=3min
OnUnitActiveSec=${INT}min
Unit=autoheal.service
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
[ "$(get AUTOHEAL_ENABLED 1)" = "1" ] && sudo systemctl enable --now autoheal.timer || sudo systemctl disable --now autoheal.timer 2>/dev/null || true
log "[97-autoheal] timer=${INT}min"
