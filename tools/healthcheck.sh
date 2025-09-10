#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

LOG_DIR="/var/log/${REPO_NAME}"; mkdir -p "$LOG_DIR"
DIG_OPTS="+time=2 +tries=1 +short"

hcr_ok(){ [ -n "$HC_RUNTIME_UUID" ] && curl -fsS --max-time 5 "https://hc-ping.com/${HC_RUNTIME_UUID}" >/dev/null 2>&1 || true; }
hcr_fail(){ [ -n "$HC_RUNTIME_UUID" ] && curl -fsS --max-time 5 "https://hc-ping.com/${HC_RUNTIME_UUID}/fail" >/dev/null 2>&1 || true; }

FAIL=0; WARN=0; DETAILS=()

sudo dpkg --audit >/dev/null 2>&1 || { WARN=$((WARN+1)); DETAILS+=("dpkg audit varningar"); }
for s in unbound pihole-FTL; do systemctl is-active --quiet "$s" || { FAIL=$((FAIL+1)); DETAILS+=("Tjänst nere: $s"); }; done
sudo unbound-checkconf >/dev/null 2>&1 || { FAIL=$((FAIL+1)); DETAILS+=("unbound-checkconf fel"); }

dig @${UNBOUND_LISTEN%%#*} -p ${UNBOUND_LISTEN##*#} google.com $DIG_OPTS >/dev/null 2>&1 || { FAIL=$((FAIL+1)); DETAILS+=("Unbound svarar ej"); }
dig @127.0.0.1 -p 53 pi-hole.net $DIG_OPTS >/dev/null 2>&1 || { FAIL=$((FAIL+1)); DETAILS+=("Pi-hole svarar ej"); }

SUMMARY="Fel: $FAIL, Varningar: $WARN"
if [ "$FAIL" -gt 0 ]; then hcr_fail; ntfy "health-fail" "$SUMMARY — ${DETAILS[*]}"; exit 1
elif [ "$WARN" -gt 0 ]; then hcr_ok; ntfy "health-warn" "$SUMMARY — ${DETAILS[*]}"; exit 0
else hcr_ok; ntfy "health-ok" "Allt OK på ${PI_HOSTNAME}"; exit 0; fi
