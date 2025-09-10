#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"
command -v pihole >/dev/null 2>&1 || { log "[20-pihole] Pi-hole ej installerad (styrs av steps/30)"; exit 0; }
# Tvinga upstream från env om någon ändrat i UI
sudo pihole -a setdns "$PIHOLE_UPSTREAM" --quiet || true
sudo systemctl restart pihole-FTL || true
log "[20-pihole] upstream: $PIHOLE_UPSTREAM"
