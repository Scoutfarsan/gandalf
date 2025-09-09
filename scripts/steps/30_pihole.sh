#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

if [ -f "/etc/pihole/setupVars.conf" ]; then
  log "setupVars.conf finns redan"
else
  sudo install -m 0644 -o root -g root "$ROOT_DIR/pihole/setupVars.conf.template" /etc/pihole/setupVars.conf
  sudo sed -i "s|__WEBPASSWORD__|${PIHOLE_WEBPASSWORD:-changeme}|g" /etc/pihole/setupVars.conf
fi
sudo pihole -a setdns 127.0.0.1#5353 --quiet || true
sudo systemctl restart pihole-FTL || true
log "Pi-hole konfigurerad"

