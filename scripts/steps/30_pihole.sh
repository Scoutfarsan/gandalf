#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

# Upstream-DNS för Pi-hole -> Unbound (kan styras via .env)
UP="${PIHOLE_UPSTREAM:-127.0.0.1#5335}"

log "Konfigurerar Pi-hole (upstream: ${UP})"

# Se till att katalogen finns (Pi-hole förväntar sig denna)
sudo mkdir -p /etc/pihole

# Om du har en template i repo, lägg in den första gången
if [ ! -f "/etc/pihole/setupVars.conf" ] && [ -f "$ROOT_DIR/pihole/setupVars.conf.template" ]; then
  sudo install -m 0644 -o root -g root "$ROOT_DIR/pihole/setupVars.conf.template" /etc/pihole/setupVars.conf
fi

# Sätt admin-lösenord om det finns i .env (utan interaktiv prompt)
if [ -n "${PIHOLE_WEBPASSWORD:-}" ]; then
  sudo pihole -a -p "${PIHOLE_WEBPASSWORD}" || true
fi

# Sätt upstream-DNS och starta om FTL
sudo pihole -a setdns "${UP}" --quiet || true
sudo systemctl restart pihole-FTL || true

log "Pi-hole konfigurerad med upstream ${UP}"
ntfy "pihole-config" "Pi-hole klar med upstream ${UP}"
