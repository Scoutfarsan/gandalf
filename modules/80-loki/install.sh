#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

[ -n "${LOKI_URL:-}" ] || { log "[loki] hoppar (saknar LOKI_URL)"; exit 0; }

sudo apt-get update -y && sudo apt-get install -y curl
PROMCONF="${PROMTAIL_CONFIG:-/etc/promtail/config.yml}"
PROMPOS="${PROMTAIL_POSITIONS:-/var/lib/promtail/positions.yaml}"

sudo mkdir -p "$(dirname "$PROMCONF")" "$(dirname "$PROMPOS")"
sudo tee "$PROMCONF" >/dev/null <<EOF
server:
  http_listen_port: 9080
positions:
  filename: ${PROMPOS}
clients:
  - url: ${LOKI_URL}/loki/api/v1/push
scrape_configs:
  - job_name: syslog
    static_configs:
      - targets: [localhost]
        labels:
          job: syslog
          __path__: /var/log/*.log
EOF

# enkel promtail via dockerless binary (laddar senaste)
if ! command -v promtail >/dev/null 2>&1; then
  ARCH=$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')
  curl -fsSL -o /usr/local/bin/promtail "https://github.com/grafana/loki/releases/latest/download/promtail-linux-${ARCH}.zip" || true
  if [ -s /usr/local/bin/promtail ]; then chmod +x /usr/local/bin/promtail; else
    # fallback – installera via apt om zip misslyckas (skippa i så fall)
    log "[loki] promtail bin kunde inte hämtas (valfritt att lägga in manuellt)"; exit 0
  fi
fi

sudo tee /etc/systemd/system/promtail.service >/dev/null <<EOF
[Unit]
Description=Promtail
After=network-online.target
[Service]
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=${PROMCONF}
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now promtail.service
log "[loki] promtail igång mot ${LOKI_URL}"
