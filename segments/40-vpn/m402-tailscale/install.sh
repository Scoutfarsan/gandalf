#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
if [ -n "${TS_AUTHKEY:-}" ]; then
  tailscale up --auth-key="${TS_AUTHKEY}" \
    --advertise-routes="${TS_ADVERTISE_ROUTES:-}" \
    --accept-dns=${TS_ACCEPT_DNS:-true} \
    --advertise-exit-node=${TS_ADVERTISE_EXIT:-true} || true
fi
echo "[m402-tailscale] Done."
