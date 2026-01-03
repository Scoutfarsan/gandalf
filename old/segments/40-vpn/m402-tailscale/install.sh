#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh; load_env
curl -fsSL https://tailscale.com/install.sh | sh || true
if [ -n "" ]; then
  tailscale up --authkey="" --hostname="" --accept-dns=true || true
fi