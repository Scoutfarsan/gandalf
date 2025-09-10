#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

LISTEN="$UNBOUND_LISTEN"
ADDR="${LISTEN%%#*}"
PORT="${LISTEN##*#}"

log "[40] Unbound -> ${ADDR}:${PORT}"
sudo apt-get update -y && sudo apt-get install -y unbound

echo 'include: "/etc/unbound/unbound.conf.d/pi-hole.conf"' | sudo tee /etc/unbound/unbound.conf >/dev/null
sudo mkdir -p /etc/unbound/unbound.conf.d

sudo tee /etc/unbound/unbound.conf.d/pi-hole.conf >/dev/null <<EOF
server:
  interface: ${ADDR}
  port: ${PORT}
  do-udp: yes
  do-tcp: yes
  prefetch: yes
  qname-minimisation: $(get UNBOUND_QNAME_MINIMIZATION "yes")
  cache-min-ttl: $(get UNBOUND_CACHE_MIN_TTL "120")
  cache-max-ttl: $(get UNBOUND_CACHE_MAX_TTL "86400")
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  do-not-query-localhost: no
EOF

sudo rm -f /var/lib/unbound/root.key
sudo unbound-anchor -a /var/lib/unbound/root.key || true
id unbound >/dev/null 2>&1 && sudo chown unbound:unbound /var/lib/unbound/root.key || true
sudo chmod 644 /var/lib/unbound/root.key

sudo unbound-checkconf
sudo systemctl enable --now unbound
sudo systemctl restart unbound
log "[40] klar"
