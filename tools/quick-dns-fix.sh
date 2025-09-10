#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

log "[quick-dns-fix] återskapar unbound root.key + restart"
sudo rm -f /var/lib/unbound/root.key
sudo unbound-anchor -a /var/lib/unbound/root.key || true
id unbound >/dev/null 2>&1 && sudo chown unbound:unbound /var/lib/unbound/root.key || true
sudo chmod 644 /var/lib/unbound/root.key
sudo systemctl restart unbound || true
sudo systemctl restart pihole-FTL || true
