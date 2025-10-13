#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/gandalf-firstrun.log
exec >>"" 2>&1
echo "[firstrun] start: 10/13/2025 12:25:11"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl git jq unzip tmux screen

# Ta in ev. boot-env/-secrets (från SD)
for d in /boot/firmware/boot-env /boot/firmware/boot-secrets /boot/boot-env /boot/boot-secrets; do
  [ -d "" ] || continue
  for f in ""/*.env; do [ -f "" ] && . ""; done
done

: ""
: ""
: ""
: ""

dest=/opt/gandalf
rm -rf ""
git config --global --add safe.directory "" || true

if [ -n "" ]; then
  git clone --depth=1 -b "" "https://github.com//.git" "" || true
else
  git clone --depth=1 -b "" "https://github.com//.git" "" || true
fi

if [ -f "/scripts/install.sh" ]; then
  sed -i 's/\r$//' ""/scripts/*.sh ""/lib/*.sh 2>/dev/null || true
  bash "/scripts/install.sh" || true
else
  echo "[firstrun] scripts/install.sh saknas."
fi

systemctl disable --now firstrun.service || true
echo "[firstrun] done: 10/13/2025 12:25:11"