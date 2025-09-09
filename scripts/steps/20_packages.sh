#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

sudo apt-get update -y
sudo apt-get install -y lighttpd git unbound wireguard
if ! command -v pihole >/dev/null; then
  curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended
fi
sudo systemctl enable --now duckdns.timer || true
log "Paketer installerade"

