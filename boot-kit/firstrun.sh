#!/usr/bin/env bash
# boot-kit/firstrun.sh — gandalf v6.43
set -euo pipefail
LOG=/var/log/gandalf-firstrun.log
exec > >(tee -a "$LOG") 2>&1
echo "[firstrun] start: $(date)"

BOOT=/boot/firmware
BOOT_ENV="$BOOT/boot-env"
BOOT_SEC="$BOOT/boot-secrets"

REPO_OWNER=${REPO_OWNER:-Scoutfarsan}
REPO_NAME=${REPO_NAME:-gandalf}
REPO_URL=${REPO_URL:-"https://github.com/${REPO_OWNER}/${REPO_NAME}.git"}

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl ca-certificates jq

# 1) Kopiera env/secrets från BOOT
install -d -m 0755 /etc/gandalf/env /etc/gandalf/secrets
[ -d "$BOOT_ENV" ] && cp -n "$BOOT_ENV"/* /etc/gandalf/env/ || true
[ -d "$BOOT_SEC" ] && cp -n "$BOOT_SEC"/* /etc/gandalf/secrets/ || true
chmod 700 /etc/gandalf/secrets || true
chmod 600 /etc/gandalf/secrets/* 2>/dev/null || true

# 2) SOPS/age bootstrap
AGE_DIR="/etc/gandalf/keys/age"
install -d -m 0755 "$AGE_DIR"

# Importera age.key om den finns
if [ -f "$BOOT_SEC/age.key" ]; then
  install -m 600 "$BOOT_SEC/age.key" "$AGE_DIR/age.key"
  echo "[firstrun] importerade age.key"
fi

# Generera age.key om saknas och lägg public på BOOT
if [ ! -f "$AGE_DIR/age.key" ]; then
  apt-get install -y age >/dev/null 2>&1 || true
  if command -v age-keygen >/dev/null 2>&1; then
    age-keygen -o "$AGE_DIR/age.key" >/dev/null 2>&1 || true
    chmod 600 "$AGE_DIR/age.key"
    awk '/^# public key:/ {print $0}' "$AGE_DIR/age.key" | sed 's/# public key: //' > "$BOOT_SEC/age.pub"
    echo "[firstrun] genererade age.key (public age.pub på BOOT)"
  else
    echo "[firstrun] age-keygen saknas; hoppar keygen."
  fi
fi

# Dekryptera repo-bundlade *.env.enc om age.key finns
if [ -f "$AGE_DIR/age.key" ] && ls env/*.env.enc secrets/*.env.enc >/dev/null 2>&1; then
  [ -x scripts/sops-setup.sh ] && bash scripts/sops-setup.sh || true
  [ -x scripts/sops-decrypt.sh ] && bash scripts/sops-decrypt.sh || true
fi

# 3) Klona repo
install -d -m 0755 /opt
if [ ! -d "/opt/${REPO_NAME}/.git" ]; then
  git clone "$REPO_URL" "/opt/${REPO_NAME}"
fi
cd "/opt/${REPO_NAME}"

# 4) Kör full install
if [ -x scripts/install.sh ]; then
  bash scripts/install.sh
else
  echo "[firstrun] scripts/install.sh saknas."
fi

systemctl disable firstrun.service || true
echo "[firstrun] done: $(date)"
