#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

[ "$(get TLS_ENABLE 0)" = "1" ] || { log "[tls-caddy] av"; exit 0; }
MODE="${TLS_MODE:-local}"; DOMAIN="${TLS_DOMAIN:-}"; EMAIL="${TLS_EMAIL:-}"; PORTAL="${TLS_PORTAL_DOMAIN:-}"

# install
if ! command -v caddy >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | sed -e 's#https://dl.cloudsmith.io/public/caddy/stable/debian any-version main#https://dl.cloudsmith.io/public/caddy/stable/debian all main#' \
    | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  sudo apt-get update -y && sudo apt-get install -y caddy
fi

# lighttpd bind lokalt
sudo mkdir -p /etc/lighttpd
echo 'server.bind = "127.0.0.1"' | sudo tee /etc/lighttpd/external.conf >/dev/null
sudo systemctl restart lighttpd || true

# ufw
command -v ufw >/dev/null 2>&1 && { sudo ufw allow 80/tcp || true; sudo ufw allow 443/tcp || true; }

# Caddyfile
CF=/etc/caddy/Caddyfile
if [ "$MODE" = "letsencrypt_http" ]; then
  [ -n "$DOMAIN" ] && [ -n "$EMAIL" ] || { echo "TLS_DOMAIN/TLS_EMAIL krävs"; exit 1; }
  PH="$DOMAIN"; [ -n "$PORTAL" ] && PH="$PORTAL"
  sudo tee "$CF" >/dev/null <<EOF
{
  email ${EMAIL}
}
:80 {
  @pi { host ${DOMAIN} }
  redir @pi https://${DOMAIN}{uri}
  respond "Not found" 404
}
${DOMAIN} { encode zstd gzip; reverse_proxy 127.0.0.1:80 }
${PH}     { encode zstd gzip; reverse_proxy 127.0.0.1:${WG_PORTAL_PORT} }
EOF
else
  HOST="${DOMAIN:-:443}"
  sudo tee "$CF" >/dev/null <<EOF
:80 { redir https://{host}{uri} }
${HOST} {
  tls internal
  encode zstd gzip
  @pihole path /admin* /admin/* /
  handle @pihole { reverse_proxy 127.0.0.1:80 }
  handle_path /wg* { reverse_proxy 127.0.0.1:${WG_PORTAL_PORT} }
}
EOF
fi

sudo systemctl enable --now caddy
sudo systemctl restart caddy
log "[tls-caddy] mode=$MODE domain=${DOMAIN:-local}"
