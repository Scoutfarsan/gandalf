#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
apt-get update -y && apt-get install -y --no-install-recommends wpasupplicant rfkill
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<WPA
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=${WIFI_COUNTRY:-SE}
network={ ssid="${WIFI_SSID1:-ssid1}"; psk="${WIFI_PSK1:-}"; priority=30 }
network={ ssid="${WIFI_SSID2:-ssid2}"; psk="${WIFI_PSK2:-}"; priority=20 }
network={ ssid="${WIFI_SSID3:-ssid3}"; psk="${WIFI_PSK3:-}"; priority=10 }
WPA
rfkill unblock wifi || true
systemctl enable --now wpa_supplicant.service || true
echo "[m103-wifi-failover] Done."
