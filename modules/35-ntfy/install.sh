#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"
# Enkel verifikation + testskott
[ -n "${NTFY_URL:-}" ] || [ -n "${NTFY_RUNTIME_URL:-}" ] || [ -n "${NTFY_SETUP_URL:-}" ] || { log "[ntfy] hoppar (ingen URL)"; exit 0; }
ntfy "ntfy-ok" "NTFY integrerad på ${PI_HOSTNAME}"
log "[ntfy] verifierad"
