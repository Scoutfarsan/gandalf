#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

UP="${PIHOLE_UPSTREAM:-127.0.0.1#5335}"

# Säkerställ att katalogen finns
sudo mkdir -p /etc/pihole

if [ ! -f "/etc/pihole/setupVars.conf" ]; then
  sudo install -m 0644 -o root -g root "$ROOT_DIR/pihole/setupVars.conf.template" /etc/pihole/setupVars.conf
  [ -n "${PIHOLE_WEBPASSWORD:-}" ] && sudo sed -i "s|WEBPASSWORD=.*|WEBPASSWORD=${PIHOLE_WEBPASSWORD}|" /etc/pihole/setupVars.conf || true
fi

# Ställ in upstream och starta om
sudo pihole -a setdns "$UP" --quiet || true
sudo systemctl restart pihole-FTL || true
log "Pi-hole konfigurerad med upstream $UP"
