#!/usr/bin/env bash
set -euo pipefail
export TERM=xterm
export DEBIAN_FRONTEND=noninteractive

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

hc_ping() {
  local suffix="${1:-}"
  [ -n "$HC_SETUP_UUID" ] || return 0
  curl -fsS --max-time 5 "https://hc-ping.com/${HC_SETUP_UUID}${suffix}" >/dev/null 2>&1 || true
}

trap 'code=$?; hc_ping "/fail"; ntfy "setup-fail ($code)" "Se /var/log/${REPO_NAME}/run.log"' ERR

hc_ping "/start"
ntfy "setup-start" "Firstboot startar på ${PI_HOSTNAME}"

bash "$ROOT_DIR/scripts/run.sh" | tee -a "/var/log/${REPO_NAME}/run.log"

hc_ping
ntfy "setup-done" "Firstboot klar på ${PI_HOSTNAME}"
