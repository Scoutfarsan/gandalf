#!/usr/bin/env bash
set -euo pipefail
logfile="/var/log/recover-net.log"; EVENTS="/var/log/gandalf-events.log"; touch "$EVENTS"
echo "$(date '+%F %T') [INFO] Startar återställning..." | tee -a "$logfile"
systemctl stop wg-quick@wg0 2>>"$logfile" || true
ip route replace default via 192.168.100.1 dev eth0 2>>"$logfile" || true
systemctl restart ssh 2>>"$logfile" || true
if ping -c1 -W2 192.168.100.1 >/dev/null 2>&1; then msg="✅ LAN-åtkomst återställd"; sev="INFO"; chan="info"; else msg="⚠️ Nät ej tillgängligt efter återställning"; sev="WARN"; chan="error"; fi
/usr/local/bin/ntfy-send "$chan" "$msg" --title "[gandalf] Recover"
/bin/echo "$(date -Is)|recover|$sev|$msg" >>"$EVENTS"; echo "$(date '+%F %T') [INFO] $msg" | tee -a "$logfile"
