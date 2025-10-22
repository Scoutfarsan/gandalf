#!/usr/bin/env bash
set -o pipefail

log(){ echo "[ $(date +'%F %T') ] $*"; }

_clean_env_file(){  # BOM + CRLF
  local f="$1"; [ -f "$f" ] || return 0
  sed -i $'1s/^\uFEFF//' "$f" 2>/dev/null || true
  sed -i 's/\r$//'        "$f" 2>/dev/null || true
}

_safe_source_env(){ # Endast KEY=VALUE
  local f="$1"; [ -f "$f" ] || return 0
  _clean_env_file "$f"
  local tmp; tmp="$(mktemp)"
  awk '
    /^[[:space:]]*#/ {next}
    /^[[:space:]]*$/ {next}
    /`/ {next}
    /\$\(/ {next}
    /[()]/ {next}
    /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/ {print}
  ' "$f" > "$tmp"
  # shellcheck disable=SC1090
  . "$tmp"
  rm -f "$tmp"
}

load_env(){
  # 1) icke-hemligt
  for d in /etc/gandalf/env /opt/gandalf/env; do
    [ -d "$d" ] || continue
    for f in "$d"/*.env; do [ -f "$f" ] && _safe_source_env "$f"; done
  done
  # 2) hemligheter
  for d in /etc/gandalf/secrets /opt/gandalf/secrets; do
    [ -d "$d" ] || continue
    for f in "$d"/*.env; do [ -f "$f" ] && _safe_source_env "$f"; done
  done

  # 3) defaults (robusta)
  : "${PI_HOSTNAME:=gandalf}"
  : "${LAN_BASE:=10.20.30}"     # => 10.20.30.0/24
  : "${VPN_BASE:=10.20.35}"     # => 10.20.35.0/24

  # Härledda + säkra fallback för PI_IP
  : "${PI_IP:=${LAN_BASE}.2}"
  export LAN_CIDR="${LAN_BASE}.0/24"
  export LAN_GW="${LAN_BASE}.1"
  export PI_IP

  export WG_NETWORK="${VPN_BASE}.0/24"
  export WG_SERVER_IP="${VPN_BASE}.1"

  # Exportera allt vi har satt/läst till sub-shells
  export PI_HOSTNAME LAN_BASE VPN_BASE WG_NETWORK WG_SERVER_IP LAN_CIDR LAN_GW TZ LOCALE
}

ensure_reqs(){
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl git jq unzip tmux screen
}
