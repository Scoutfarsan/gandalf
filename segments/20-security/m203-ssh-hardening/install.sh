#!/usr/bin/env bash
set -euo pipefail
SSHD=/etc/ssh/sshd_config.d/99-gandalf.conf
install -d -m 0755 /etc/ssh/sshd_config.d
cat >"$SSHD" <<'CFG'
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
CFG
systemctl restart ssh || systemctl restart sshd || true
echo "[m203-ssh-hardening] Done."
