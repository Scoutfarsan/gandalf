#!/usr/bin/env bash
set -euo pipefail
apt-get install -y unbound
cat >/etc/unbound/unbound.conf.d/pi.conf <<'CONF'
server:
    interface: 127.0.0.1
    port: 5335
    do-ip6: no
    qname-minimisation: yes
    verbosity: 0
CONF
systemctl restart unbound