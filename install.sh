#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

sudo mkdir -p "$INSTALL_DIR" "/var/log/${REPO_NAME}"

sudo tee /etc/systemd/system/firstboot-runner.service >/dev/null <<EOF
[Unit]
Description=Kör ${REPO_NAME} första gången efter installation
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
Environment=TERM=xterm
Environment=DEBIAN_FRONTEND=noninteractive
WorkingDirectory=${INSTALL_DIR}
ExecStart=/bin/bash -lc '${INSTALL_DIR}/firstboot-runner.sh'
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now firstboot-runner.service
