#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh; load_env
IP="${PI_IP:-$(hostname -I | awk "{print \$1}")}"
add_line() { grep -qE "^[[:space:]]*$1([[:space:]]|$)" /etc/hosts || echo "$1" >> /etc/hosts; }
add_line "$IP gandalf.lan gandalf"
echo "[m105-hosts] /etc/hosts ok"
