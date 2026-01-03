#!/usr/bin/env bash
set -euo pipefail
apt-get update -y
apt-get install -y unbound wget
cat >/etc/unbound/unbound.conf.d/pi-hole.conf <<EOC
server:
    interface: 127.0.0.1
    port: 5335
    do-ip6: no
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    cache-min-ttl: 60
    cache-max-ttl: 86400
    root-hints: "/var/lib/unbound/root.hints"
EOC
wget -qO /var/lib/unbound/root.hints https://www.internic.net/domain/named.root || true
systemctl enable --now unbound
echo "[m302-unbound] Up on 127.0.0.1#5335"
