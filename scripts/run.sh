#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

mkdir -p "/var/log/${REPO_NAME}"

START_FROM=0
if [ "${1:-}" = "--from" ] && [ -n "${2:-}" ]; then START_FROM="$2"; fi

for step in "$ROOT_DIR/scripts/steps/"*"_*.sh"; do
  num="$(basename "$step" | cut -d'_' -f1)"
  if [ "$num" -lt "$START_FROM" ]; then
    log "Skippar $(basename "$step") (börjar från $START_FROM)"
    continue
  fi
  log "Kör $(basename "$step")"
  ntfy "setup-step" "Startar $(basename "$step")"
  bash "$step"
  ntfy "setup-step" "Klar $(basename "$step")"
done

bash "$ROOT_DIR/scripts/modules-run.sh"
