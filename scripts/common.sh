#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
LOG_DIR="/var/log/${REPO_NAME:-pihole}"
mkdir -p "$LOG_DIR"
[ -f "$ENV_FILE" ] && { set -a; . "$ENV_FILE"; set +a; }

log() { echo "[$(date +%F %T)] $*" | tee -a "$LOG_DIR/main.log"; }

ntfy() {
  local title="$1"; shift; local msg="$*"
  [ -n "${NTFY_RUNTIME_URL:-}" ] && curl -fsS --max-time 5 -H "Title: ${title}" -d "${msg}" "$NTFY_RUNTIME_URL" >/dev/null 2>&1 || true
  [ -n "${NTFY_URL:-}" ]        && curl -fsS --max-time 5 -H "Title: ${title}" -d "${msg}" "$NTFY_URL"        >/dev/null 2>&1 || true
}

ntfy_setup() {
  local title="$1"; shift; local msg="$*"
  [ -n "${NTFY_SETUP_URL:-}" ] && curl -fsS --max-time 5 -H "Title: ${title}" -d "${msg}" "$NTFY_SETUP_URL" >/dev/null 2>&1 || true
  [ -n "${NTFY_URL:-}" ]       && curl -fsS --max-time 5 -H "Title: ${title}" -d "${msg}" "$NTFY_URL"       >/dev/null 2>&1 || true
}

req() { command -v "$1" >/dev/null || { log "Installerar $1"; sudo apt-get update -y && sudo apt-get install -y "$1"; }; }
