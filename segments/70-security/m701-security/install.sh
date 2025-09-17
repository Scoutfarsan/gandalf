#!/usr/bin/env bash
set -euo pipefail
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y ufw fail2ban
ufw allow 53 || true
ufw allow 80,443/tcp || true
ufw allow 51820/udp || true
ufw allow 22/tcp || true
ufw deny 8088/tcp || true
ufw --force enable || true
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
ignoreip = 127.0.0.1/8 10.20.30.0/24
bantime  = 7200
findtime = 600
maxretry = 5
backend  = systemd
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = %(sshd_log)s
EOF
systemctl enable --now fail2ban
echo "[m701-security] ufw+fail2ban deployed (LAN whitelist, 2h bantime)"
