#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

sudo install -m 0644 -o root -g root "$ROOT_DIR/unbound/pi-hole.conf" /etc/unbound/unbound.conf.d/pi-hole.conf
sudo systemctl enable --now unbound
sudo systemctl restart unbound
log "Unbound (bas) konfigurerad"

