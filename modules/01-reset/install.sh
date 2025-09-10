#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"
# Nollställ markeringsfiler m.m. (icke-destruktivt)
sudo rm -f /var/lib/${REPO_NAME}/autoheal/*.stamp 2>/dev/null || true
sudo mkdir -p /var/lib/${REPO_NAME}/autoheal /var/log/${REPO_NAME}
log "[01-reset] klart"
