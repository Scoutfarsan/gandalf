#!/usr/bin/env bash
set -euo pipefail
STATE_FILE="/var/lib/${REPO_NAME}/autoheal.json"
TTL_MIN=${AUTOHEAL_TTL_MINUTES:-240}
MAX_ATTEMPTS=${AUTOHEAL_MAX_ATTEMPTS:-1}
SERVICES=("pihole-FTL" "unbound" "wg-quick@${WG_INTERFACE:-wg0}" "caddy")

mkdir -p "$(dirname "$STATE_FILE")"
[ -f "$STATE_FILE" ] || echo "{}" > "$STATE_FILE"

jq_get() { jq -r "$1" "$STATE_FILE"; }
jq_set() { tmp=$(mktemp); jq "$1" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"; }

now_ts=$(date +%s)

for svc in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$svc"; then
    continue
  fi
  last_ts=$(jq_get ".\"$svc\".last_ts // 0")
  attempts=$(jq_get ".\"$svc\".attempts // 0")
  age_min=$(( (now_ts - last_ts) / 60 ))
  if (( attempts >= MAX_ATTEMPTS )) && (( age_min < TTL_MIN )); then
    echo "[autoheal] Skip $svc: attempts=$attempts age=${age_min}m < TTL=${TTL_MIN}m"
    continue
  fi
  if (( age_min >= TTL_MIN )); then
    attempts=0
  fi
  echo "[autoheal] Restarting $svc (attempt $((attempts+1))/$MAX_ATTEMPTS)"
  if systemctl restart "$svc"; then
    echo "[autoheal] $svc restarted OK"
    jq_set ".\"$svc\" = {\"last_ts\": $now_ts, \"attempts\": 0}"
  else
    echo "[autoheal] $svc restart FAILED"
    jq_set ".\"$svc\" = {\"last_ts\": $now_ts, \"attempts\": $((attempts+1))}"
  fi
done
