#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

[ -n "$HC_RUNTIME_UUID" ] || { log "[95-healthchecks] hoppar (saknar HC_RUNTIME_UUID)"; exit 0; }

sudo tee /etc/systemd/system/${REPO_NAME}-hc.service >/dev/null <<EOF
[Unit]
Description=${REPO_NAME} hc ping
[Service]
Type=oneshot
ExecStart=/usr/bin/curl -fsS https://hc-ping.com/${HC_RUNTIME_UUID}
EOF

sudo tee /etc/systemd/system/${REPO_NAME}-hc.timer >/dev/null <<'EOF'
[Unit]
Description=Hourly Healthchecks ping
[Timer]
OnCalendar=hourly
Unit=gandalf-hc.service
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ${REPO_NAME}-hc.timer
log "[95-healthchecks] ping hourly"
