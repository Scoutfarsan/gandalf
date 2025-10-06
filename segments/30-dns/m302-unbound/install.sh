#!/usr/bin/env bash
set -euo pipefail
apt-get update -y && apt-get install -y unbound
cat >/etc/unbound/unbound.conf.d/pi-hole.conf <<'CONF'
server:
  verbosity: 0
  interface: 127.0.0.1
  port: 5335
  do-ip4: yes
  do-udp: yes
  do-tcp: yes
  qname-minimisation: yes
  cache-min-ttl: 120
  cache-max-ttl: 86400
forward-zone:
  name: "."
  forward-addr: 1.1.1.1@853#cloudflare-dns.com
  forward-addr: 1.0.0.1@853#cloudflare-dns.com
  forward-tls-upstream: yes
CONF
curl -fsSLo /var/lib/unbound/root.hints https://www.internic.net/domain/named.root || true
systemctl enable --now unbound
echo "[m302-unbound] Done."
