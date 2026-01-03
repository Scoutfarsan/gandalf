#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%F %T'; }

LOG="/var/log/net-report.log"
STATE="/run/net-report.health"
COOLDOWN_SEC=300
RECOVER_DIR="/var/lib/gandalf"
RECOVER_TS="${RECOVER_DIR}/last_recover_epoch"

mkdir -p /var/log /run "$RECOVER_DIR" || true

notify() {
  local title="${1:-}" body="${2:-}"
  if command -v send-ntfy >/dev/null 2>&1; then
    send-ntfy "$title" "$body" || true
  fi
}

summary_body() {
  local def gw eth wlan wg
  def="$(ip route | awk '/^default/ {print $5; exit}' 2>/dev/null || echo "-")"
  gw="$(ip route | awk '/^default/ {print $3; exit}' 2>/dev/null || echo "-")"
  eth="$(ip -4 -o addr show dev eth0 2>/dev/null | awk '{print $4}' | head -n1 || true)"
  wlan="$(ip -4 -o addr show dev wlan0 2>/dev/null | awk '{print $4}' | head -n1 || true)"
  wg="$(ip -4 -o addr show dev wg0 2>/dev/null | awk '{print $4}' | head -n1 || true)"
  cat <<EOT
$(ts)
Host: $(hostname)
Default dev: ${def} (gw ${gw})
eth0: ${eth:-"-"}  wlan0: ${wlan:-"-"}  wg0: ${wg:-"-"}
EOT
}

can_recover() {
  local now last
  now="$(date +%s)"
  last="$(cat "$RECOVER_TS" 2>/dev/null || echo 0)"
  if (( now - last >= COOLDOWN_SEC )); then
    return 0
  fi
  echo "$(ts) [WARN] recover cooldown aktiv (${COOLDOWN_SEC}s). Skippar recover. (senast=$last now=$now)" | tee -a "$LOG" >/dev/null
  return 1
}

mark_recover() {
  date +%s > "$RECOVER_TS" 2>/dev/null || true
}

do_recover() {
  local reason="${1:-unknown}"
  if can_recover; then
    echo "$(ts) [WARN] recover trigger: ${reason}" | tee -a "$LOG" >/dev/null
    /usr/local/bin/recover-net.sh || true
    mark_recover
    notify "Auto-recover" "⚠️ $(hostname): ${reason}. Återställning körd (cooldown ${COOLDOWN_SEC}s)."
    return 0
  else
    notify "Recover throttled" "⏳ $(hostname): Recover behövdes (${reason}) men cooldown är aktiv (${COOLDOWN_SEC}s)."
    return 0
  fi
}

do_health() {
  local defdev gw prev cur
  defdev="$(ip route | awk '/^default/ {print $5; exit}' 2>/dev/null || echo "-")"
  gw="$(ip route | awk '/^default/ {print $3; exit}' 2>/dev/null || echo "-")"

  if [[ "$defdev" == "wg0" ]]; then
    do_recover "Default-route via wg0"
    cur="RECOVER:wg0"
  else
    if [[ "$gw" != "-" ]] && ! ping -c1 -W2 "$gw" >/dev/null 2>&1; then
      do_recover "Gateway ${gw} ej nåbar"
      cur="RECOVER:gw"
    else
      cur="OK:${defdev}"
    fi
  fi

  prev="$(cat "$STATE" 2>/dev/null || true)"
  echo "$cur" > "$STATE"

  if [[ "$cur" != "$prev" ]]; then
    echo "$(ts) [INFO] state change: ${prev:-<none>} -> ${cur}" | tee -a "$LOG" >/dev/null
    if [[ "$cur" == OK:* ]]; then
      notify "Nätverk OK" "✅ $(hostname): nätverk OK via ${defdev}"
    fi
  fi
}

daily_if_bad() {
  local cur
  cur="$(cat "$STATE" 2>/dev/null || echo "UNKNOWN")"
  if [[ "$cur" != OK:* ]]; then
    notify "Nätverk EJ OK" "❌ $(hostname): ${cur}\n\n$(summary_body)"
    echo "$(ts) [WARN] daily_if_bad: ${cur} -> skickade rapport" | tee -a "$LOG" >/dev/null
  else
    echo "$(ts) [INFO] daily_if_bad: OK -> ingen rapport" | tee -a "$LOG" >/dev/null
  fi
}

MODE="${1:-}"
case "$MODE" in
  --health)       do_health ;;
  --daily)        notify "Daglig nätverksrapport" "$(summary_body)" ;;
  --daily-if-bad) daily_if_bad ;;
  --on-recover)   notify "LAN-åtkomst återställd" "$(summary_body)" ;;
  *) echo "usage: $0 [--health|--daily|--daily-if-bad|--on-recover]" >&2; exit 2 ;;
esac

exit 0
