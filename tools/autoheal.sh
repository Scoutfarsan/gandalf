#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

LOG_DIR="/var/log/${REPO_NAME}"
STATE_DIR="/var/lib/${REPO_NAME}/autoheal"
mkdir -p "$LOG_DIR" "$STATE_DIR"

log(){ echo "[$(date '+%F %T')]" "$@" | tee -a "$LOG_DIR/autoheal.log"; }
stamp_path(){ echo "${STATE_DIR}/$(echo "$1" | tr '/ ' '__').stamp"; }

hc_start(){ [ -n "$HC_AUTOHEAL_UUID" ] && curl -fsS --max-time 5 "https://hc-ping.com/${HC_AUTOHEAL_UUID}/start" >/dev/null 2>&1 || true; }
hc_ok(){    [ -n "$HC_AUTOHEAL_UUID" ] && curl -fsS --max-time 5 "https://hc-ping.com/${HC_AUTOHEAL_UUID}" >/dev/null 2>&1 || true; }
hc_fail(){  [ -n "$HC_AUTOHEAL_UUID" ] && curl -fsS --max-time 5 "https://hc-ping.com/${HC_AUTOHEAL_UUID}/fail" >/dev/null 2>&1 || true; }

notify(){ ntfy "$1" "$2"; }

# ========= konfig via env =========
# Lista över mål vi försöker heala, komma-sep. Tom => defaultlista.
TARGETS="$(get AUTOHEAL_TARGETS "")"
if [ -z "$TARGETS" ]; then
  TARGETS="dpkg,unbound,pihole-FTL,wireguard,tailscale,dns-probe"
fi
IFS=',' read -r -a TARGET_ARR <<< "$TARGETS"

# Max hur ofta samma mål får healas automatiskt (minuter)
COOLDOWN_MIN="$(get AUTOHEAL_COOLDOWN_MINUTES "120")"

# ========= hjälp =========
should_try(){
  local name="$1" p; p="$(stamp_path "$name")"
  if [ ! -s "$p" ]; then return 0; fi
  local last ts_now diff
  last="$(cut -d' ' -f1 < "$p" 2>/dev/null || echo 0)"
  ts_now="$(date +%s)"
  diff=$(( ts_now - last ))
  [ "$diff" -ge $(( COOLDOWN_MIN * 60 )) ]
}

mark_fail(){  # spara timestamp + orsak
  local name="$1" reason="$2" p; p="$(stamp_path "$name")"
  printf '%s %s\n' "$(date +%s)" "$reason" > "$p"
}
clear_fail(){
  local name="$1" p; p="$(stamp_path "$name")"
  [ -f "$p" ] && rm -f "$p" || true
}

# ========= kontroller =========
ok_dpkg(){ sudo dpkg --audit >/dev/null 2>&1; }
fix_dpkg(){ sudo dpkg --configure -a -D --force-confnew || true; sudo apt-get -f install -y || true; }

ok_service(){ systemctl is-active --quiet "$1"; }
restart_service(){ sudo systemctl restart "$1"; }

ok_unbound(){
  sudo unbound-checkconf >/dev/null 2>&1 || return 1
  dig @"${UNBOUND_LISTEN%%#*}" -p "${UNBOUND_LISTEN##*#}" google.com +time=2 +tries=1 +short >/dev/null 2>&1
}
fix_unbound(){
  sudo rm -f /var/lib/unbound/root.key
  sudo unbound-anchor -a /var/lib/unbound/root.key || true
  id unbound >/dev/null 2>&1 && sudo chown unbound:unbound /var/lib/unbound/root.key || true
  sudo chmod 644 /var/lib/unbound/root.key
  restart_service unbound
}

ok_pihole(){
  dig @127.0.0.1 -p 53 pi-hole.net +time=2 +tries=1 +short >/dev/null 2>&1
}
fix_pihole(){
  # säkerställ att upstream i pihole matchar env
  if command -v pihole >/dev/null 2>&1; then
    sudo pihole -a setdns "$PIHOLE_UPSTREAM" --quiet || true
  fi
  restart_service pihole-FTL
}

ok_wg(){
  ok_service "wg-quick@${WG_INTERFACE}.service"
}
fix_wg(){
  sudo systemctl enable --now "wg-quick@${WG_INTERFACE}.service" || true
  # öppna port om UFW finns
  if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow "${WG_PORT}"/udp || true
  fi
}

ok_ts(){
  systemctl is-active --quiet tailscaled && tailscale status >/dev/null 2>&1
}
fix_ts(){
  sudo systemctl enable --now tailscaled || true
  local args=(--hostname="$TS_HOSTNAME")
  [ -n "$TS_AUTHKEY" ] && args+=(--authkey="$TS_AUTHKEY")
  [ -n "$TS_ADVERTISE_ROUTES" ] && args+=(--advertise-routes="$TS_ADVERTISE_ROUTES")
  [ "$(get_bool TS_ACCEPT_DNS true)" = "true" ] && args+=(--accept-dns=true)
  [ "$(get_bool TS_ADVERTISE_EXIT false)" = "true" ] && args+=(--advertise-exit-node)
  sudo tailscale up "${args[@]}" || true
}

ok_dns_probe(){
  # snabb dubbel-probe: först Unbound-porten, sedan Pi-hole
  dig @"${UNBOUND_LISTEN%%#*}" -p "${UNBOUND_LISTEN##*#}" example.com +time=2 +tries=1 +short >/dev/null 2>&1 &&
  dig @127.0.0.1 -p 53 example.org +time=2 +tries=1 +short >/dev/null 2>&1
}
fix_dns_probe(){
  # mjuk sekvens: unbound → pihole → (om wg/tailscale defaultar DNS) bumpa dem också
  fix_unbound || true
  fix_pihole || true
  if systemctl is-enabled --quiet "wg-quick@${WG_INTERFACE}.service"; then fix_wg || true; fi
  if systemctl is-enabled --quiet tailscaled; then fix_ts || true; fi
}

# ========= körning =========
hc_start
FAILED=0
DETAILS=()

for tgt in "${TARGET_ARR[@]}"; do
  name="$(echo "$tgt" | xargs)"  # trim
  case "$name" in
    dpkg)
      if ok_dpkg; then clear_fail "$name"; log "OK   $name"
      else
        if should_try "$name"; then
          log "HEAL $name → dpkg --configure -a"
          if fix_dpkg && ok_dpkg; then clear_fail "$name"; notify "autoheal" "dpkg lås fixat på ${PI_HOSTNAME}"
          else FAILED=$((FAILED+1)); DETAILS+=("$name"); mark_fail "$name" "dpkg-fail"; fi
        else log "SKIP $name (cooldown)"; FAILED=$((FAILED+1)); DETAILS+=("$name"); fi
      fi
      ;;
    unbound)
      if ok_unbound; then clear_fail "$name"; log "OK   $name"
      else
        if should_try "$name"; then
          log "HEAL $name → unbound-anchor + restart"
          if fix_unbound && ok_unbound; then clear_fail "$name"; notify "autoheal" "Unbound återställd på ${PI_HOSTNAME}"
          else FAILED=$((FAILED+1)); DETAILS+=("$name"); mark_fail "$name" "unbound-fail"; fi
        else log "SKIP $name (cooldown)"; FAILED=$((FAILED+1)); DETAILS+=("$name"); fi
      fi
      ;;
    pihole-FTL|pihole)
      if ok_pihole; then clear_fail "$name"; log "OK   pihole"
      else
        if should_try "$name"; then
          log "HEAL $name → restart pihole-FTL"
          if fix_pihole && ok_pihole; then clear_fail "$name"; notify "autoheal" "Pi-hole återställd på ${PI_HOSTNAME}"
          else FAILED=$((FAILED+1)); DETAILS+=("pihole"); mark_fail "$name" "pihole-fail"; fi
        else log "SKIP $name (cooldown)"; FAILED=$((FAILED+1)); DETAILS+=("pihole"); fi
      fi
      ;;
    wireguard|wg)
      if ok_wg; then clear_fail "$name"; log "OK   wireguard"
      else
        if should_try "$name"; then
          log "HEAL $name → wg-quick up"
          if fix_wg && ok_wg; then clear_fail "$name"; notify "autoheal" "WireGuard återställd på ${PI_HOSTNAME}"
          else FAILED=$((FAILED+1)); DETAILS+=("wireguard"); mark_fail "$name" "wg-fail"; fi
        else log "SKIP $name (cooldown)"; FAILED=$((FAILED+1)); DETAILS+=("wireguard"); fi
      fi
      ;;
    tailscale|ts)
      if ok_ts; then clear_fail "$name"; log "OK   tailscale"
      else
        if should_try "$name"; then
          log "HEAL $name → tailscale up"
          if fix_ts && ok_ts; then clear_fail "$name"; notify "autoheal" "Tailscale återställd på ${PI_HOSTNAME}"
          else FAILED=$((FAILED+1)); DETAILS+=("tailscale"); mark_fail "$name" "ts-fail"; fi
        else log "SKIP $name (cooldown)"; FAILED=$((FAILED+1)); DETAILS+=("tailscale"); fi
      fi
      ;;
    dns-probe)
      if ok_dns_probe; then clear_fail "$name"; log "OK   dns-probe"
      else
        if should_try "$name"; then
          log "HEAL $name → sequence fix"
          if fix_dns_probe && ok_dns_probe; then clear_fail "$name"; notify "autoheal" "DNS flow återställd på ${PI_HOSTNAME}"
          else FAILED=$((FAILED+1)); DETAILS+=("dns"); mark_fail "$name" "dns-fail"; fi
        else log "SKIP $name (cooldown)"; FAILED=$((FAILED+1)); DETAILS+=("dns"); fi
      fi
      ;;
    *)
      log "IGN  okänt mål: $name"
      ;;
  esac
done

if [ "$FAILED" -gt 0 ]; then
  hc_fail
  notify "autoheal-fail" "Misslyckad autoheal på ${PI_HOSTNAME}. Felmål: ${DETAILS[*]}"
  exit 1
else
  hc_ok
  log "Autoheal klar: allt OK"
  exit 0
fi
