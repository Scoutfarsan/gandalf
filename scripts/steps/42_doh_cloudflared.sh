#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

MODE="${RESOLVER_MODE:-recursive}"
LISTEN="${CLOUDFLARED_LISTEN:-127.0.0.1:5053}"
UPSTREAMS="${CLOUDFLARED_UPSTREAMS:-https://cloudflare-dns.com/dns-query,https://dns.quad9.net/dns-query,https://dns.google/dns-query}"
if [ "$MODE" != "doh" ]; then log "RESOLVER_MODE=$MODE → hoppar över cloudflared."; exit 0; fi
if ! command -v cloudflared >/dev/null 2>&1; then
  if sudo apt-get update -y && sudo apt-get install -y cloudflared; then
    log "Installerade cloudflared via Debian."
  else
    curl -fsSL https://pkg.cloudflare.com/cloudflared/install.sh | sudo bash
    sudo apt-get install -y cloudflared
  fi
fi
ADDR="${LISTEN%:*}"; PORT="${LISTEN#*:}"; CFG="/etc/cloudflared/config.yml"
sudo mkdir -p /etc/cloudflared
{ echo "proxy-dns: true"; echo "proxy-dns-address: ${ADDR}"; echo "proxy-dns-port: ${PORT}"; echo "max-ttl: 86400"; echo "bootstrap: 1.1.1.1,9.9.9.9"; echo "upstream:";
  IFS=',' read -r -a ups <<< "$UPSTREAMS"; for u in "${ups[@]}"; do echo "  - ${u}"; done; } | sudo tee "$CFG" >/dev/null
sudo systemctl enable --now cloudflared; sudo systemctl restart cloudflared
CONF_DIR="/etc/unbound/unbound.conf.d"; LOCAL="$CONF_DIR/pi-hole-doh-local.conf"
sudo bash -lc "cat > '$LOCAL' <<'EOF'
server:
    verbosity: 0
    interface: 127.0.0.1
    port: 5353
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    edns-buffer-size: 1232
    prefetch: yes
    qname-minimisation: yes
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    do-not-query-localhost: no
forward-zone:
    name: "."
    forward-tls-upstream: no
    forward-addr: 127.0.0.1@'${PORT}'
EOF"
sudo rm -f "$CONF_DIR/pi-hole.conf" "$CONF_DIR/pi-hole-dot.conf" || true
sudo systemctl enable --now unbound; sudo systemctl restart unbound
log "Unbound → cloudflared (${LISTEN}) → DoH upstreams klara."
ntfy "resolver" "Aktiverat DoH via cloudflared"

