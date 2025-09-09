#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
ntfy "ntfy-check" "ntfy runtime fungerar (test)"; [ -n "${NTFY_SETUP_URL:-}" ] && curl -fsS -H "Title: setup-check" -d "setup topic fungerar (test)" "$NTFY_SETUP_URL" || true; log "ntfy verifierad"
