#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

VPN="$VPN_PROVIDER"; WG_IF="$WG_INTERFACE"; WG_PORT="$WG_PORT"; TS_EXIT="$(get TS_ADVERTISE_EXIT "false")"

ensure_tail(){
  command -v tailscale >/dev/null 2>&1 || curl -fsSL https://tailscale.com/install.sh | sudo bash
  sudo systemctl enable --now tailscaled
  local args=(--hostname="$TS_HOSTNAME")
  [ -n "$TS_AUTHKEY" ] && args+=(--authkey="$TS_AUTHKEY")
  [ -n "$TS_ADVERTISE_ROUTES" ] && args+=(--advertise-routes="$TS_ADVERTISE_ROUTES")
  [ "$(get_bool TS_ACCEPT_DNS true)" = "true" ] && args+=(--accept-dns=true)
  [ "$(get_bool TS_ADVERTISE_EXIT false)" = "true" ] && args+=(--advertise-exit-node)
  sudo tailscale up "${args[@]}" || true
}
ensure_wg(){
  sudo apt-get update -y && sudo apt-get install -y wireguard
  sudo systemctl enable --now wg-quick@"$WG_IF".service || true
  command -v ufw >/dev/null 2>&1 && sudo ufw allow "$WG_PORT"/udp || true
}
stop_tail(){ sudo tailscale down 2>/dev/null || true; sudo systemctl disable --now tailscaled 2>/dev/null || true; }
stop_wg(){ sudo systemctl disable --now wg-quick@"$WG_IF".service 2>/dev/null || true; command -v ufw >/dev/null 2>&1 && sudo ufw delete allow "$WG_PORT"/udp 2>/dev/null || true; }

case "$VPN" in
  wireguard) stop_tail; ensure_wg ;;
  tailscale) stop_wg; ensure_tail ;;
  both)
    ensure_wg; ensure_tail
    if [ "$TS_EXIT" = "true" ]; then
      sudo tailscale up --hostname="$TS_HOSTNAME" \
        $( [ -n "$TS_ADVERTISE_ROUTES" ] && echo --advertise-routes="$TS_ADVERTISE_ROUTES" ) \
        $( [ "$(get_bool TS_ACCEPT_DNS true)" = "true" ] && echo --accept-dns=true ) \
        --advertise-exit-node=false || true
    fi
    ;;
  *) stop_tail; ensure_wg ;;
esac
log "[vpn-select] provider=$VPN"
