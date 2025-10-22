#!/usr/bin/env bash
# Var tolerant mot odefinierade tills env är laddad
set -eo pipefail
set +u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"

# Normalisera radslut i repo (tyst)
find "$REPO_ROOT" -type f \( -name "*.sh" -o -name "*.service" -o -name "*.conf" -o -name ".order" \) \
  -exec sed -i $'1s/^\uFEFF//' {} \; -exec sed -i 's/\r$//' {} \; 2>/dev/null || true

# Ladda helpers + env
. "${REPO_ROOT}/lib/common.sh" || { echo "[install] kunde inte sourca common.sh"; exit 1; }
load_env
ensure_reqs

# Nu kan vi vara strikta
set -u

LOG="${LOG:-/var/log/gandalf-install.log}"
mkdir -p "$(dirname "$LOG")" || true
{ exec > >(tee -a "$LOG") 2>&1; } || { echo "[warn] kunde inte tee till $LOG, kör på stdout"; }

log "[install] start; REPO_ROOT=${REPO_ROOT} LAN=${LAN_CIDR:-<empty>} PI=${PI_IP:-<empty>}"

SEG_ROOT="${REPO_ROOT}/segments"
ORDER=(10-core 30-dns 40-vpn 50-tools 60-tls 80-ops 90-infra) # 20-security körs separat
: "${MODULE_TIMEOUT:=300}"

for seg in "${ORDER[@]}"; do
  [ -d "${SEG_ROOT}/${seg}" ] || { log "[install] skip ${seg} (saknas)"; continue; }
  if [ -f "${SEG_ROOT}/${seg}/.order" ]; then
    while read -r m; do
      [[ -z "$m" || "${m:0:1}" == "#" ]] && continue
      s="${SEG_ROOT}/${seg}/${m}/install.sh"
      if [ -f "$s" ]; then
        chmod +x "$s" 2>/dev/null || true
        sed -i 's/\r$//' "$s" 2>/dev/null || true
        start_ts=$(date +%s)
        log "[install] ▶ ${seg}/${m} start"
        if timeout --preserve-status "${MODULE_TIMEOUT}" bash "$s"; then
          end_ts=$(date +%s); dur=$((end_ts-start_ts))
          log "[install] ✔ ${seg}/${m} ok (${dur}s)"
        else
          rc=$?
          end_ts=$(date +%s); dur=$((end_ts-start_ts))
          log "[install] ✖ ${seg}/${m} fail rc=${rc} (${dur}s) — fortsätter"
        fi
      else
        log "[install] skip ${seg}/${m} (install.sh saknas)"
      fi
    done < "${SEG_ROOT}/${seg}/.order"
  else
    log "[install] .order saknas i ${seg} – hoppar"
  fi
done

log "[install] done"
