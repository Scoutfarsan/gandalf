#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
hostnamectl set-hostname "${PI_HOSTNAME:-gandalf}" || true
cat >/etc/dhcpcd.conf <<CONF
interface eth0
metric ${ETH_METRIC:-100}
interface wlan0
metric ${WIFI_METRIC:-200}
CONF
echo "[m101-network] Done."
