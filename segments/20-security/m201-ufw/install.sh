#!/usr/bin/env bash
set -euo pipefail
apt-get update -y && apt-get install -y ufw
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 51820/udp
ufw allow 80,443/tcp
ufw allow 53/udp
ufw --force enable
echo "[m201-ufw] Done."
