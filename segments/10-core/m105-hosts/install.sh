#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
cat >/etc/hosts <<HOSTS
127.0.0.1   localhost
${PI_IP:-10.20.30.2}  ${PI_HOSTNAME:-gandalf} ${PI_HOSTNAME:-gandalf}.lan pihole.lan
HOSTS
echo "[m105-hosts] Done."
