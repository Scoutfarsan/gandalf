#!/usr/bin/env bash
# scripts/install.sh — gandalf v6.43
set -euo pipefail
. /opt/gandalf/lib/common.sh; load_env; ensure_reqs

LOG=/var/log/gandalf-install.log
exec > >(tee -a "$LOG") 2>&1

log "[install] start"
emit_ntfy "Install start på $(hostname)" "gandalf" "hammer_and_wrench"

SEG_ROOT="/opt/gandalf/segments"
for seg in 10-core 20-security 30-dns 40-vpn 50-tools 60-tls 80-ops 90-infra; do
  [ -d "$SEG_ROOT/$seg" ] || continue
  [ -f "$SEG_ROOT/$seg/.order" ] || continue
  log "[install] segment $seg"
  while read -r m; do
    [ -z "$m" ] && continue
    [[ "${m:0:1}" == "#" ]] && continue
    script="$SEG_ROOT/$seg/$m/install.sh"
    if [ -x "$script" ]; then
      log "[install] run $seg/$m"
      bash "$script"
    else
      log "[install] skip $seg/$m (saknar install.sh)"
    fi
  done < "$SEG_ROOT/$seg/.order"
done

emit_ntfy "Install klar på $(hostname)" "gandalf" "white_check_mark"
log "[install] done"
