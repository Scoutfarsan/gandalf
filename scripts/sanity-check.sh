#!/usr/bin/env bash
# scripts/sanity-check.sh — v6.43
set -euo pipefail
miss=0
for v in PI_HOSTNAME LAN_BASE PI_IP LAN_GW VPN_BASE WG_SERVER_IP; do
  if ! printenv | grep -q "^$v="; then echo "MISSING: $v"; miss=1; fi
done
exit $miss
