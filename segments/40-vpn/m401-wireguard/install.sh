#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
apt-get update -y && apt-get install -y wireguard qrencode
WG_IF="${WG_INTERFACE:-wg0}"
WG_SRV_IP="${WG_SERVER_IP:-10.20.35.1}"
install -d -m 0700 /etc/wireguard
if [ ! -f "/etc/wireguard/${WG_IF}.conf" ]; then
  umask 077
  wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub
  cat >"/etc/wireguard/${WG_IF}.conf" <<CFG
[Interface]
Address = ${WG_SRV_IP}/24
ListenPort = ${WG_PORT:-51820}
PrivateKey = $(cat /etc/wireguard/server.key)
SaveConfig = true
PostUp = ufw route allow in on ${WG_IF} out on eth0; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = ufw route delete allow in on ${WG_IF} out on eth0; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
CFG
fi
sysctl -w net.ipv4.ip_forward=1
systemctl enable --now "wg-quick@${WG_IF}"
echo "[m401-wireguard] Done."
