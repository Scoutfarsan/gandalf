#!/usr/bin/env bash
set -euo pipefail
if [[ ! -f /etc/wireguard/wg0.conf ]]; then
  install -m 600 "$(dirname "$0")/wg0.conf.sample" /etc/wireguard/wg0.conf
  echo "[wireguard] Skapade wg0.conf från sample – lägg in PrivateKey och rätt uplink-interface."
fi
systemctl enable --now wg-quick@${WG_INTERFACE:-wg0} || true
