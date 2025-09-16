#!/usr/bin/env bash
set -euo pipefail
ufw allow 53 || true
ufw allow 80,443/tcp || true
ufw allow 51820/udp || true
ufw deny 8088/tcp || true
ufw --force enable || true
systemctl enable --now fail2ban || true
