#!/usr/bin/env bash
set -euo pipefail
apt-get install -y ufw
ufw allow 22/tcp
ufw allow 53
ufw allow 80,443/tcp
ufw allow 51820/udp
ufw --force enable