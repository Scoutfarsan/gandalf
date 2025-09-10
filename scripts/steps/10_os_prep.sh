#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

log "[10] OS-prep"
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl git ufw

# TZ/locale
echo "$TZ" | sudo tee /etc/timezone >/dev/null
sudo ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime || true
sudo sed -i "s/^# *${LOCALE}/${LOCALE}/" /etc/locale.gen || true
sudo locale-gen || true

# Hostname
echo "$PI_HOSTNAME" | sudo tee /etc/hostname >/dev/null
sudo hostnamectl set-hostname "$PI_HOSTNAME" || true

# UFW baseline
sudo ufw --force enable || true
sudo ufw allow 22/tcp || true
log "[10] klar"
