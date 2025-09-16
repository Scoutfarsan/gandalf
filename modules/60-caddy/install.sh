#!/usr/bin/env bash
set -euo pipefail
install -m 644 "$(dirname "$0")/Caddyfile" /etc/caddy/Caddyfile
systemctl enable --now caddy || true
systemctl reload caddy || true
