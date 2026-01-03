#!/usr/bin/env bash
set -euo pipefail
[ -r /opt/gandalf/env/ntfy.env ] && set +u && . /opt/gandalf/env/ntfy.env && set -u
NTFY_URL="${NTFY_URL:-}"; NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_TOKEN="${NTFY_TOKEN:-}"; NTFY_USER="${NTFY_USER:-}"; NTFY_PASS="${NTFY_PASS:-}"
NTFY_NOTIFY_ON_OK="${NTFY_NOTIFY_ON_OK:-1}"; NTFY_SHOW_HOST="${NTFY_SHOW_HOST:-1}"
gandalf_ntfy() {
  [ -n "$NTFY_URL" ] && [ -n "$NTFY_TOPIC" ] || return 0
  local t="$1" m="${2:-}" p="${3:-3}" tags="${4:-}" click="${5:-}" host; host="$(hostname)"
  [ "$NTFY_SHOW_HOST" = "1" ] && t="[$host] $t"
  local args=(-fsS -X POST "${NTFY_URL%/}/$NTFY_TOPIC" -H "Title: $t" -H "Priority: $p")
  [ -n "$tags" ]  && args+=(-H "Tags: $tags"); [ -n "$click" ] && args+=(-H "Click: $click")
  if [ -n "$NTFY_TOKEN" ]; then args+=(-H "Authorization: Bearer $NTFY_TOKEN")
  elif [ -n "$NTFY_USER" ] || [ -n "$NTFY_PASS" ]; then args+=(-u "${NTFY_USER}:${NTFY_PASS}"); fi
  printf "%s\n" "$m" | curl "${args[@]}" >/dev/null || true
}
