#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
OUT=/etc/dnsmasq.d/99-gandalf-dhcp.conf
LAN="${LAN_BASE:-10.20.30}"
cat >"$OUT" <<CONF
dhcp-range=${LAN}.11,${LAN}.19,12h
dhcp-range=${LAN}.31,${LAN}.39,12h
dhcp-range=${LAN}.41,${LAN}.49,12h
dhcp-range=${LAN}.51,${LAN}.59,12h
dhcp-range=${LAN}.61,${LAN}.69,12h
dhcp-range=${LAN}.71,${LAN}.79,12h
dhcp-range=${LAN}.81,${LAN}.89,12h
dhcp-range=${LAN}.91,${LAN}.99,12h
dhcp-option=option:router,${LAN}.1
dhcp-option=option:dns-server,${LAN}.2
CONF
if [ "${DHCP_ACTIVATE:-0}" = "1" ]; then systemctl restart pihole-FTL || true; fi
echo "[m304-dhcp] wrote $OUT"
