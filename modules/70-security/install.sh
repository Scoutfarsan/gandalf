#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

# 1) UFW – tillåt pågående SSH-port (22/tcp eller ENV SSH_PORT)
SSH_PORT="$(get SSH_PORT "22")"
sudo apt-get update -y && sudo apt-get install -y ufw
sudo ufw allow "${SSH_PORT}/tcp" || true
sudo ufw allow 80/tcp || true
sudo ufw allow 443/tcp || true
sudo ufw allow ${WG_PORT}/udp || true
sudo ufw --force enable || true

# 2) SSHD säkerhet (utan att kasta ut oss)
SSHD=/etc/ssh/sshd_config.d/${REPO_NAME}.conf
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee "$SSHD" >/dev/null <<EOF
# ${REPO_NAME} secure defaults
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication yes
LoginGraceTime 30
ClientAliveInterval 120
ClientAliveCountMax 3
EOF
sudo systemctl reload ssh || sudo systemctl restart ssh

# 3) Sysctl – aktivera IP forward (behövs för WG) men inget aggressivt
SYS=/etc/sysctl.d/99-${REPO_NAME}.conf
sudo tee "$SYS" >/dev/null <<'EOF'
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
sudo sysctl -p "$SYS" || true

log "[70-security] UFW, SSH och sysctl uppdaterade (utan att låsa ut dig)."
