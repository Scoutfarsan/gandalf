#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"
sudo apt-get update -y && sudo apt-get install -y qrencode

BASE="${WG_PORTAL_BASE_URL:-http://$PI_HOSTNAME.lan:${WG_PORTAL_PORT}}"
T="${WG_REQUEST_TOKEN:-}"
URL="${BASE}/wg/request?t=${T}"

echo "URL: ${URL}"
qrencode -t ANSIUTF8 "${URL}"
