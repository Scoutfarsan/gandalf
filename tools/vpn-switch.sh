#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

mode="${1:-both}"
case "$mode" in
  wireguard) sudo systemctl enable --now wg-quick@"$WG_INTERFACE".service; sudo systemctl disable --now tailscaled 2>/dev/null || true ;;
  tailscale) sudo systemctl disable --now wg-quick@"$WG_INTERFACE".service 2>/dev/null || true; sudo systemctl enable --now tailscaled ;;
  both)      sudo systemctl enable --now wg-quick@"$WG_INTERFACE".service; sudo systemctl enable --now tailscaled ;;
  *) echo "Använd: $0 [wireguard|tailscale|both]"; exit 1 ;;
esac
echo "VPN-läge: $mode"
