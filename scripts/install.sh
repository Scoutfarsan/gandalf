#!/usr/bin/env bash
set -euo pipefail
. "/../lib/common.sh"; load_env; ensure_reqs

LOG=/var/log/gandalf-install.log
exec > >(tee -a "") 2>&1
log "[install] start; LAN= PI="

SEG_ROOT="/opt/gandalf/segments"
ORDER=(10-core 30-dns 40-vpn 50-tools 60-tls 80-ops 90-infra)
  # 20-security temporärt inaktiverat
for seg in ""; do
  [ -d "/" ] || continue
  if [ -f "//.order" ]; then
    while read -r m; do
      [[ -z "" || "" == "#" ]] && continue
      s="///install.sh"
      if [ -x "" ]; then log "[install] run /"; bash ""; else log "[install] skip /"; fi
    done < "//.order"
  fi
done

log "[install] done"
