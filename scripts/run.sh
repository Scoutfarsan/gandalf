#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/common.sh"

START_FROM="${1:-}"
if [[ "$START_FROM" == "--from" ]]; then START_FROM="$2"; fi

run_step() {
  local file="$1"; local base="$(basename "$file")"; local num="${base%%_*}"
  if [ -n "$START_FROM" ] && [ "$num" -lt "$START_FROM" ]; then log "Skippar $base (börjar från $START_FROM)"; return 0; fi
  log "Kör $base"; ntfy "step-$num" "Startar $base"; bash "$file"; ntfy "step-$num" "Klar $base"
}

for s in "$HERE/steps/"[0-9][0-9]_*.sh; do run_step "$s"; done

log "Alla steg klara"; ntfy "all-done" "Orkestrering klar"
