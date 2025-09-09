#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

sudo timedatectl set-timezone "${TZ:-Europe/Stockholm}" || true
sudo hostnamectl set-hostname "${HOSTNAME:-pihole}" || true
req curl; req jq; req ufw; req ca-certificates
sudo ufw allow 22/tcp || true
sudo ufw allow 53/tcp || true
sudo ufw allow 53/udp || true
sudo ufw allow 80/tcp || true
sudo ufw allow 51820/udp || true
echo "y" | sudo ufw enable || true
log "OS prep klar"

