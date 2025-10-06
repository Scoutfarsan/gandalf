#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
apt-get update -y && apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y && apt-get install -y caddy
cat >/etc/caddy/Caddyfile <<'CADDY'
:80 {
    respond "gandalf up" 200
}
CADDY
systemctl enable --now caddy
echo "[m601-caddy] Done."
