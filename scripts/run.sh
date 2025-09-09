#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

START_FROM="${1:-0}"

for step in "$ROOT_DIR"/scripts/steps/*_*.sh; do
  num=$(basename "$step" | cut -d'_' -f1)
  if [ "$num" -lt "$START_FROM" ]; then
    log "Skippar $(basename "$step") (börjar från $START_FROM)"
    continue
  fi

  log "Kör $(basename "$step")"
  ntfy "setup-step" "Startar $(basename "$step")"
  bash "$step"
  ntfy "setup-step" "Klar med $(basename "$step")"
done

log "Alla steg klara"; ntfy "all-done" "Orkestrering klar"
