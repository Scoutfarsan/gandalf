#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh; load_env
log "[m101] start (host=$PI_HOSTNAME ip=${PI_IP:-?} tz=${TZ:-?} lc=${LOCALE:-?})"
hostnamectl set-hostname "$PI_HOSTNAME" || true
[ -n "${TZ:-}" ] && timedatectl set-timezone "$TZ" || true
if [ -n "${LOCALE:-}" ]; then
  sed -i "s/^#\(${LOCALE}\)/\1/" /etc/locale.gen || true
  locale-gen || true
fi
log "[m101] done"
