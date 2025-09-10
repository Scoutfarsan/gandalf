#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

# Sätt hostname, tz, locale (om inte redan gjort i step 10)
echo "$PI_HOSTNAME" | sudo tee /etc/hostname >/dev/null
sudo hostnamectl set-hostname "$PI_HOSTNAME" || true
echo "$TZ" | sudo tee /etc/timezone >/dev/null
sudo ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime || true

# (Valfritt) skapa /etc/hosts rad
if ! grep -q "$PI_HOSTNAME" /etc/hosts; then
  echo "${PI_IP} ${PI_HOSTNAME}" | sudo tee -a /etc/hosts >/dev/null
fi

log "[10-network] hostname/tz/hosts uppdaterade"
