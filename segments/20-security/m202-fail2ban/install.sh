#!/usr/bin/env bash
set -euo pipefail
apt-get update -y && apt-get install -y fail2ban
cat >/etc/fail2ban/jail.local <<'JAIL'
[DEFAULT]
bantime = 2h
findtime = 10m
maxretry = 6
ignoreip = 10.20.30.0/24 10.20.31.0/24 10.20.32.0/24 10.20.35.0/24
banaction = iptables-multiport
backend = systemd

[sshd]
enabled = true
mode = aggressive
action = %(action_mw)s
JAIL
systemctl enable --now fail2ban
echo "[m202-fail2ban] Done."
