#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
URLS="${DNSFILTER_URLS:-https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts}"
TMP=/tmp/adlists.txt
echo "$URLS" | tr ',' '\n' > "$TMP"
while read -r u; do [ -n "$u" ] && sqlite3 /etc/pihole/gravity.db "INSERT OR IGNORE INTO adlist (address,enabled) VALUES ('$u',1);" || true; done < "$TMP"
pihole -g || true
echo "[m303-dnsfilters] Done."
