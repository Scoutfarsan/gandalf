#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

sudo apt-get update -y && sudo apt-get install -y fail2ban
sudo tee /etc/fail2ban/jail.d/${REPO_NAME}.local >/dev/null <<'EOF'
[sshd]
enabled = true
maxretry = 6
findtime = 10m
bantime = 1h
EOF
sudo systemctl enable --now fail2ban
log "[fail2ban] aktiv"
