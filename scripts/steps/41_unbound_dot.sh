#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

MODE="${RESOLVER_MODE:-recursive}"
CONF_DIR="/etc/unbound/unbound.conf.d"
DOT_CONF="$CONF_DIR/pi-hole-dot.conf"
sudo mkdir -p "$CONF_DIR"
case "$MODE" in
  dot)
    mapfile -t providers < <(echo "${DOT_PROVIDERS:-cloudflare,quad9,google}" | tr ',' '\n' | sed 's/ *//g' | sed '/^$/d')
    addrs=()
    for p in "${providers[@]}"; do
      var="DOT_$(echo "$p" | tr '[:lower:]' '[:upper:]')"
      val="${!var:-}"
      if [ -n "$val" ]; then IFS=',' read -r -a arr <<< "$val"; for a in "${arr[@]}"; do addrs+=("$a"); done; fi
    done
    sudo install -m 0644 -o root -g root "$ROOT_DIR/unbound/pi-hole-dot.conf" "$DOT_CONF"
    { echo ""; echo "forward-zone:"; echo "    name: ".""; echo "    forward-tls-upstream: yes";
      for a in "${addrs[@]}"; do echo "    forward-addr: ${a}"; done; } | sudo tee -a "$DOT_CONF" >/dev/null
    sudo rm -f "$CONF_DIR/pi-hole.conf" || true
    sudo systemctl enable --now unbound; sudo systemctl restart unbound
    log "Unbound satt till DoT-forward med ${#addrs[@]} upstreams."
    ;;
  *) log "RESOLVER_MODE=$MODE → ingen DoT";;
esac

