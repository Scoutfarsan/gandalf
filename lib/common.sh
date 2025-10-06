#!/usr/bin/env bash
# lib/common.sh — gandalf v6.43
set -o pipefail

log(){ echo "[ $(date +'%F %T') ] $*"; }

load_env(){
  if [ -d /etc/gandalf/env ]; then for f in /etc/gandalf/env/*.env; do [ -f "$f" ] && . "$f"; done; fi
  if [ -d /etc/gandalf/secrets ]; then for f in /etc/gandalf/secrets/*.env; do [ -f "$f" ] && . "$f"; done; fi
  export HOSTNAME="${PI_HOSTNAME:-$(hostname)}"
}

ensure_reqs(){
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends ca-certificates curl git jq unzip tar
}

emit_ntfy(){
  local title="${2:-gandalf}"; local tag="${3:-rocket}"
  if [ -n "${NTFY_RUNTIME_URL:-}" ]; then
    curl -fsS -H "Title: $title" -H "Tags: $tag" -d "$1" "$NTFY_RUNTIME_URL" >/dev/null 2>&1 || true
  fi
}
