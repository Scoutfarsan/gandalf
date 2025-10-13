#!/usr/bin/env bash
set -euo pipefail
apt-get install -y fail2ban
cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 2h
findtime = 10m
maxretry = 8
ignoreip = 127.0.0.1/8 10.20.30.0/24 10.20.35.0/24
[sshd]
enabled = true
EOF
systemctl restart fail2ban