#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

WG_IF="${WG_INTERFACE:-wg0}"
sudo install -d -m 700 /etc/wireguard
CONF="/etc/wireguard/${WG_IF}.conf"
if [ ! -f "$CONF" ]; then
  sudo install -m 600 -o root -g root "$ROOT_DIR/wireguard/wg0.conf.template" "$CONF"
  sudo sed -i "s|__ADDRESS__|${WG_ADDRESS:-10.8.0.1/24}|g" "$CONF"
  sudo sed -i "s|__PORT__|${WG_PORT:-51820}|g" "$CONF"
  sudo sed -i "s|__ALLOWEDIPS__|${WG_ALLOWEDIPS:-10.8.0.0/24}|g" "$CONF"
  if ! sudo test -f /etc/wireguard/server_private.key; then
    (umask 077; sudo wg genkey | sudo tee /etc/wireguard/server_private.key >/dev/null)
    sudo sh -c 'wg pubkey < /etc/wireguard/server_private.key > /etc/wireguard/server_public.key'
  fi
  PRIV=$(sudo cat /etc/wireguard/server_private.key)
  sudo sed -i "s|__PRIVATE_KEY__|$PRIV|g" "$CONF"
fi
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wg.conf >/dev/null
sudo systemctl enable --now "wg-quick@${WG_IF}" || true
log "WireGuard konfigurerad"

