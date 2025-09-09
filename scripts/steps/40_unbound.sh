#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

LISTEN="${UNBOUND_LISTEN:-127.0.0.1#5335}"
ADDR="${LISTEN%%#*}"
PORT="${LISTEN##*#}"
CONF="/etc/unbound/unbound.conf.d/pi-hole.conf"

sudo mkdir -p /etc/unbound/unbound.conf.d

sudo tee "$CONF" >/dev/null <<EOF
server:
    verbosity: 0
    interface: ${ADDR}
    port: ${PORT}
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    so-reuseport: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    qname-minimisation: ${UNBOUND_QNAME_MINIMIZATION:-yes}
    num-threads: 1
    cache-min-ttl: ${UNBOUND_CACHE_MIN_TTL:-120}
    cache-max-ttl: ${UNBOUND_CACHE_MAX_TTL:-86400}
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    do-not-query-localhost: no
EOF

sudo unbound-checkconf
sudo systemctl enable --now unbound
sudo systemctl restart unbound
log "Unbound konfigurerad på ${ADDR}:${PORT}"
