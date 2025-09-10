#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

sudo apt-get update -y && sudo apt-get install -y python3 python3-pip
sudo pip3 install --break-system-packages flask

sudo install -d -m 0755 /opt/wg-portal /var/lib/wg-portal
sudo install -m 0644 -o root -g root "$ROOT_DIR/modules/66-wg-portal/app.py" /opt/wg-portal/app.py

sudo tee /etc/systemd/system/wg-portal.service >/dev/null <<EOF
[Unit]
Description=WG portal (Flask)
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
WorkingDirectory=${ROOT_DIR}
ExecStart=/bin/bash -lc 'source ${ROOT_DIR}/scripts/lib/env.sh; exec /usr/bin/python3 /opt/wg-portal/app.py --host "${WG_PORTAL_BIND}" --port "${WG_PORTAL_PORT}" --db "${WG_DB_PATH}"'
Restart=on-failure
User=root
Group=root
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now wg-portal.service
log "[wg-portal] lyssnar på ${WG_PORTAL_BIND}:${WG_PORTAL_PORT}"
