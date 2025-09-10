#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"
sudo systemctl enable --now unbound || true
sudo systemctl restart unbound || true
log "[25-unbound] restartad"
