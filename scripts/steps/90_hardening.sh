#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config || true; sudo systemctl restart ssh || true; log "Hardening klar"
