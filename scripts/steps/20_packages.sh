#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

log "[20] paket"
sudo apt-get update -y
sudo apt-get install -y lighttpd unbound dnsutils qrencode git
log "[20] klar"
