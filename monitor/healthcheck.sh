#!/usr/bin/env bash
set -euo pipefail
dig +time=2 +tries=1 pi-hole.net @127.0.0.1 -p 53 >/dev/null
systemctl is-active --quiet pihole-FTL
systemctl is-active --quiet unbound
systemctl is-active --quiet lighttpd
systemctl is-active --quiet wg-quick@wg0 || true
echo "OK"
