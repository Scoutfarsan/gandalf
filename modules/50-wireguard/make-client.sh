#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd 2>/dev/null || echo "/opt/${REPO_NAME:-gandalf}")"
[ -f "$ROOT_DIR/scripts/lib/env.sh" ] && . "$ROOT_DIR/scripts/lib/env.sh"

NAME="${1:-client$(date +%s)}"
WG_IF="${WG_INTERFACE:-wg0}"
WG_NET="${WG_NETWORK:-10.10.0.0/24}"
WG_DNS="${WG_DNS:-10.10.0.1}"
PORT="${WG_PORT:-51820}"

# server public key
PUB="$(sudo cat /etc/wireguard/publickey)"
# tilldela ip
NEXTIP="$(python3 - <<PY
import ipaddress,sys
net=ipaddress.ip_network("${WG_NET}", False)
print(list(net.hosts())[1])
PY
)"

# endpoint
ENDPOINT="${WG_ENDPOINT_DOMAIN:-$(hostname -I | awk '{print $1}')}:${PORT}"

# generera nycklar
umask 077; PRIV=$(wg genkey); PUBL=$(printf "%s" "$PRIV" | wg pubkey)

CONF="/etc/wireguard/clients/${NAME}.conf"
sudo tee "$CONF" >/dev/null <<EOF
[Interface]
PrivateKey = ${PRIV}
Address = ${NEXTIP}/32
DNS = ${WG_DNS}

[Peer]
PublicKey = ${PUB}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${ENDPOINT}
PersistentKeepalive = 25
EOF

sudo wg set "${WG_IF}" peer "${PUBL}" allowed-ips "${NEXTIP}/32"
qrencode -t ansiutf8 < "$CONF"
echo "Sparad: $CONF"
