#!/usr/bin/env bash
# Central env-loader + helpers (inga hårdkodade värden i skript längre)
set -euo pipefail

# --- var den här filen ligger ---
__ENV_LIB="$(readlink -f "${BASH_SOURCE[0]}")"
__ROOT_DIR="$(cd "$(dirname "$__ENV_LIB")/../.." && pwd)"

# --- Läs in env i denna ordning (sist vinner) ---
_env_files=(
  "/boot/firmware/secrets.env"
  "/boot/firmware/.env"
  "$__ROOT_DIR/secrets.env"
  "$__ROOT_DIR/.env"
)

for f in "${_env_files[@]}"; do
  if [ -f "$f" ]; then
    # shellcheck disable=SC1090
    set -a; . "$f"; set +a
  fi
done

# --- Hjälpare ---
get() { # get VAR [default]
  local __k="${1:?}"; local __d="${2:-}"
  printf '%s' "${!__k-$__d}"
}
get_bool() { # get_bool VAR [default true|false]
  local v; v="$(printf '%s' "$(get "$1" "${2:-false}")" | tr '[:upper:]' '[:lower:]')"
  case "$v" in 1|true|yes|on) echo "true";; *) echo "false";; esac
}
need() { # need VAR
  local __k="${1:?}"; if [ -z "$(get "$__k")" ]; then echo "Missing required: $__k" >&2; exit 1; fi
}
log() { echo "[$(date '+%F %T')]" "$@"; }
_ntfy_post(){ local t="$1"; shift; local m="$*"; curl -fsS --max-time 5 -H "Title: $t" -d "$m" "$1" >/dev/null 2>&1 || true; }
ntfy(){ local t="$1"; shift; local m="$*"
  local a b c; a="$(get NTFY_RUNTIME_URL)"; b="$(get NTFY_URL)"; c="$(get NTFY_SETUP_URL)"
  [ -n "$a" ] && _ntfy_post "$t" "$m" "$a"
  [ -n "$b" ] && _ntfy_post "$t" "$m" "$b"
  [ -n "$c" ] && _ntfy_post "$t" "$m" "$c"
}

# --- Smarta defaults (utan hårdkodning) ---
export REPO_OWNER="$(get REPO_OWNER "Scoutfarsan")"
export REPO_NAME="$(get REPO_NAME "gandalf")"
export INSTALL_DIR="$(get INSTALL_DIR "/opt/${REPO_NAME}")"

# Hostname-logik
__HOST_SYS="$(hostname -s 2>/dev/null || echo pi)"
export PI_HOSTNAME="$(get PI_HOSTNAME "$__HOST_SYS")"
export TS_HOSTNAME="$(get TS_HOSTNAME "$PI_HOSTNAME")"

# Nät
export LAN_CIDR="$(get LAN_CIDR "192.168.0.0/16")"
export LAN_GW="$(get LAN_GW "192.168.100.1")"
export PI_IP="$(get PI_IP "192.168.100.2")"
export PI_IFACE="$(get PI_IFACE "eth0")"  # inga antaganden om eth0 om du vill override:a

# Unbound/Pi-hole port/addr (ingen hårdkodning)
export UNBOUND_LISTEN="$(get UNBOUND_LISTEN "127.0.0.1#5335")"
export PIHOLE_UPSTREAM="$(get PIHOLE_UPSTREAM "$UNBOUND_LISTEN")"

# Healthchecks
export HC_SETUP_UUID="$(get HC_SETUP_UUID "")"
export HC_RUNTIME_UUID="$(get HC_RUNTIME_UUID "")"
# valfri autoheal-uuid
export HC_AUTOHEAL_UUID="$(get HC_AUTOHEAL_UUID "")"

# WG defaults
export WG_INTERFACE="$(get WG_INTERFACE "wg0")"
export WG_PORT="$(get WG_PORT "51820")"
export WG_NETWORK="$(get WG_NETWORK "10.10.0.0/24")"
export WG_DNS="$(get WG_DNS "10.10.0.1")"
export WG_ENDPOINT_DOMAIN="$(get WG_ENDPOINT_DOMAIN "")"
export WG_ADVERTISE_EXIT="$(get WG_ADVERTISE_EXIT "true")"

# Tailscale
export VPN_PROVIDER="$(get VPN_PROVIDER "both")"
export TS_AUTHKEY="$(get TS_AUTHKEY "")"
export TS_ADVERTISE_ROUTES="$(get TS_ADVERTISE_ROUTES "")"
export TS_ACCEPT_DNS="$(get TS_ACCEPT_DNS "true")"
export TS_ADVERTISE_EXIT="$(get TS_ADVERTISE_EXIT "false")"

# WG-portal
export WG_PORTAL_BIND="$(get WG_PORTAL_BIND "0.0.0.0")"
export WG_PORTAL_PORT="$(get WG_PORTAL_PORT "8088")"
export WG_PORTAL_ADMIN_KEY="$(get WG_PORTAL_ADMIN_KEY "")"
export WG_PORTAL_BASE_URL="$(get WG_PORTAL_BASE_URL "http://$PI_HOSTNAME.lan:${WG_PORTAL_PORT}")"
export WG_REQUEST_TOKEN="$(get WG_REQUEST_TOKEN "")"
export WG_DB_PATH="$(get WG_DB_PATH "/var/lib/wg-portal/db.sqlite")"
export NTFY_WG_ISSUE_URL="$(get NTFY_WG_ISSUE_URL "")"

# TLS / Caddy
export TLS_ENABLE="$(get TLS_ENABLE "0")"
export TLS_MODE="$(get TLS_MODE "local")"
export TLS_DOMAIN="$(get TLS_DOMAIN "")"
export TLS_EMAIL="$(get TLS_EMAIL "")"
export TLS_PORTAL_DOMAIN="$(get TLS_PORTAL_DOMAIN "")"

# Nextcloud
export MODULE_nextcloud="$(get MODULE_nextcloud "0")"

# Övrigt
export LOG_LEVEL="$(get LOG_LEVEL "info")"
export TZ="$(get TZ "Europe/Stockholm")"
export LOCALE="$(get LOCALE "sv_SE.UTF-8")"

# Exportera varenda key som script kan behöva (redan gjort via set -a för env-filer ovan)
true
