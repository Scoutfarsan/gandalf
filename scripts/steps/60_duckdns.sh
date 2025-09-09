#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
sudo systemctl enable --now duckdns.timer; log "DuckDNS timer aktiv"
