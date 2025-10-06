#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
apt-get update -y
curl -fsSL https://install.pi-hole.net | PIHOLE_SKIP_OS_CHECK=true bash /dev/stdin --unattended
if [ -n "${PIHOLE_WEBPASSWORD:-}" ]; then pihole -a -p "$PIHOLE_WEBPASSWORD"; fi
sed -i 's/^PIHOLE_DNS_.*/PIHOLE_DNS_1=127.0.0.1#5335/' /etc/pihole/setupVars.conf || true
systemctl restart pihole-FTL
echo "[m301-pihole] Done."
