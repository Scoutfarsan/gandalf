#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

DOMAIN="${DUCKDNS_DOMAIN:-}"
TOKEN="${DUCKDNS_TOKEN:-}"
[ -n "$DOMAIN" ] && [ -n "$TOKEN" ] || { log "[15-duckdns] hoppar (saknar DUCKDNS_DOMAIN/TOKEN)"; exit 0; }

sudo tee /etc/systemd/system/duckdns.service >/dev/null <<EOF
[Unit]
Description=DuckDNS updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/curl -fsS "https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip="
EOF

sudo tee /etc/systemd/system/duckdns.timer >/dev/null <<'EOF'
[Unit]
Description=Update DuckDNS var 5:e minut
[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=duckdns.service
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now duckdns.timer
log "[15-duckdns] aktiv för ${DOMAIN}"
