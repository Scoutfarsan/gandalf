#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

run_mod() {
  local dir="$1" name var flag
  name="$(basename "$dir")"
  var="MODULE_${name#*-}"
  flag="$(get "$var" "1")"
  [ "$flag" = "1" ] || { log "Skippar modul $name ($var=0)"; return 0; }
  [ -x "$dir/install.sh" ] || { log "Skippar modul $name (saknar install.sh)"; return 0; }
  log "Kör modul $name"; ntfy "module" "Startar $name"; bash "$dir/install.sh"; ntfy "module" "Klar $name"
}

for d in "$ROOT_DIR/modules/"*"-"*; do [ -d "$d" ] && run_mod "$d"; done
