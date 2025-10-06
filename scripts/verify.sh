#!/usr/bin/env bash
# scripts/verify.sh — v6.43
set -euo pipefail
echo "[verify] services"
systemctl status pihole-FTL unbound wg-quick@wg0 tailscaled caddy loki promtail autoheal.timer --no-pager || true
echo "[verify] DNS via unbound"
dig @127.0.0.1 -p 5335 example.com +short || true
echo "[verify] Loki ready"
curl -fsS http://127.0.0.1:3100/ready && echo OK || true
