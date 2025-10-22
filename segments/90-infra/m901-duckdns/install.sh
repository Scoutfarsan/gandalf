#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh; load_env
[ -z "" ] && { echo "[m901] no DUCKDNS_TOKEN"; exit 0; }
( crontab -l 2>/dev/null; echo "*/5 * * * * curl -fsSL \"https://www.duckdns.org/update?domains=&token=&ip=\" >/tmp/duckdns.log 2>&1" ) | crontab -
echo "[m901] duckdns updater installerad"