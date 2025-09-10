#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

curl -fsSL https://tailscale.com/install.sh | sudo bash
sudo systemctl enable --now tailscaled

ARGS=(--hostname="$TS_HOSTNAME")
[ -n "$TS_AUTHKEY" ] && ARGS+=(--authkey="$TS_AUTHKEY")
[ -n "$TS_ADVERTISE_ROUTES" ] && ARGS+=(--advertise-routes="$TS_ADVERTISE_ROUTES")
[ "$(get_bool TS_ACCEPT_DNS true)" = "true" ] && ARGS+=(--accept-dns=true)
[ "$(get_bool TS_ADVERTISE_EXIT false)" = "true" ] && ARGS+=(--advertise-exit-node)

sudo tailscale up "${ARGS[@]}" || true
log "[tailscale] up som ${TS_HOSTNAME}"
