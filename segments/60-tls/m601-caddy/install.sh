#!/usr/bin/env bash
set -euo pipefail
apt-get install -y caddy
cat >/etc/caddy/Caddyfile <<'CADDY'
:80 {
  respond /health 200 { body "ok" }
}
CADDY
systemctl enable --now caddy