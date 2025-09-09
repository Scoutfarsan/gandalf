#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
sudo install -m 0755 -o root -g root "$ROOT_DIR/monitor/healthcheck.sh" /usr/local/bin/healthcheck-pihole; if [ -n "${HC_PING_URL:-}" ]; then ( /usr/local/bin/healthcheck-pihole && curl -fsS "$HC_PING_URL" ) || true; fi; log "Monitor körd en gång"
