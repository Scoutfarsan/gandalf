#!/usr/bin/env bash
set -euo pipefail

[ -f /boot/firmware/.env ] && { set -a; . /boot/firmware/.env; set +a; }
REPO_NAME="${REPO_NAME:-pihole}"
INSTALL_DIR="${INSTALL_DIR:-/opt/${REPO_NAME}}"
ENV_FILE="$INSTALL_DIR/.env"
LOG_DIR="/var/log/${REPO_NAME}"
mkdir -p "$LOG_DIR"
[ -f "$ENV_FILE" ] && { set -a; . "$ENV_FILE"; set +a; }

# setup-start
[ -n "${NTFY_SETUP_URL:-}" ] && curl -fsS --max-time 5 -H "Title: setup-start" -d "Firstboot startar" "$NTFY_SETUP_URL" >/dev/null 2>&1 || true
[ -n "${NTFY_URL:-}" ]       && curl -fsS --max-time 5 -H "Title: setup-start" -d "Firstboot startar" "$NTFY_URL"       >/dev/null 2>&1 || true

[ -d "$INSTALL_DIR/.git" ] && git -C "$INSTALL_DIR" pull --ff-only || true
bash "$INSTALL_DIR/scripts/run.sh" | tee -a "$LOG_DIR/run.log"

# setup-done
[ -n "${NTFY_SETUP_URL:-}" ] && curl -fsS --max-time 5 -H "Title: setup-done" -d "Firstboot klar" "$NTFY_SETUP_URL" >/dev/null 2>&1 || true
[ -n "${NTFY_URL:-}" ]       && curl -fsS --max-time 5 -H "Title: setup-done" -d "Firstboot klar" "$NTFY_URL"       >/dev/null 2>&1 || true

systemctl disable firstboot-runner.service || true
