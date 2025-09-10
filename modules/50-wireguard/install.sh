#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

WG_IF="$WG_INTERFACE"; WG_PORT="$WG_PORT"; WG_NET="$WG_NETWORK"; WG_DNS="$WG_DNS"
WAN_IF="$(get WAN_IF "$(ip route show default | awk '/default/ {print $5; exit}')")"

sudo apt-get update -y && sudo apt-get install -y wireguard qrencode python3

sudo mkdir -p /etc/wireguard/clients
sudo chmod 700 /etc/wireguard
cd /etc/wireguard

if [ ! -f privatekey ]; then umask 077; wg genkey | tee privatekey | wg pubkey > publickey; fi
PRIV="$(cat privatekey)"

srv_ip="$(python3 - <<PY
import ipaddress; print(list(ipaddress.ip_network("${WG_NET}", False).hosts())[0])
PY
)"

sudo tee "/etc/wireguard/${WG_IF}.conf" >/dev/null <<EOF
[Interface]
Address = ${srv_ip}/24
ListenPort = ${WG_PORT}
PrivateKey = ${PRIV}
SaveConfig = true
PostUp   = sysctl -w net.ipv4.ip_forward=1; iptables -t nat -A POSTROUTING -o ${WAN_IF} -j MASQUERADE; iptables -A FORWARD -i ${WG_IF} -j ACCEPT; iptables -A FORWARD -o ${WG_IF} -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${WAN_IF} -j MASQUERADE; iptables -D FORWARD -i ${WG_IF} -j ACCEPT; iptables -D FORWARD -o ${WG_IF} -j ACCEPT
EOF

command -v ufw >/dev/null 2>&1 && sudo ufw allow "${WG_PORT}"/udp || true
sudo systemctl enable --now wg-quick@"${WG_IF}".service || true

# make-client helper
sudo install -m 0755 -o root -g root "${ROOT_DIR}/modules/50-wireguard/make-client.sh" /usr/local/sbin/wg-make-client
log "[wireguard] ${WG_IF} lyssnar på ${WG_PORT}/udp"
