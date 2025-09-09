#!/usr/bin/env bash
set -euo pipefail

# Läs env från Bookworm-plats först, fallback till gammal
[ -f /boot/firmware/.env ] && { set -a; . /boot/firmware/.env; set +a; } || true
[ -f /boot/.env ] && { set -a; . /boot/.env; set +a; } || true

REPO_OWNER="${REPO_OWNER:-ditt_githubkonto}"
REPO_NAME="${REPO_NAME:-gandalf}"
REPO_URL_DEFAULT="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
REPO_URL="${REPO_URL:-$REPO_URL_DEFAULT}"
INSTALL_DIR="${INSTALL_DIR:-/opt/${REPO_NAME}}"
LOG_DIR="/var/log/${REPO_NAME}"

sudo mkdir -p "$INSTALL_DIR" "$LOG_DIR"
sudo chown -R $USER: "$INSTALL_DIR" "$LOG_DIR"
command -v git >/dev/null || { sudo apt-get update -y && sudo apt-get install -y git; }

if [ ! -d "$INSTALL_DIR/.git" ]; then
  git clone "$REPO_URL_DEFAULT" "$INSTALL_DIR"
else
  git -C "$INSTALL_DIR" pull --ff-only || true
fi

# Dynamisk service med bash -lc för robust start
cat <<EOF | sudo tee /etc/systemd/system/firstboot-runner.service >/dev/null
[Unit]
Description=Kör ${REPO_NAME} första gången efter installation
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=/bin/bash -lc '${INSTALL_DIR}/firstboot-runner.sh'
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF

# DuckDNS service/timer
cat <<EOF | sudo tee /etc/systemd/system/duckdns.service >/dev/null
[Unit]
Description=Uppdatera DuckDNS
[Service]
Type=oneshot
EnvironmentFile=${INSTALL_DIR}/.env
ExecStart=/bin/bash -lc 'curl -fsS "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip="'
EOF
sudo tee /etc/systemd/system/duckdns.timer >/dev/null <<'EOF'
[Unit]
Description=Timer för DuckDNS
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=duckdns.service
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now firstboot-runner.service
