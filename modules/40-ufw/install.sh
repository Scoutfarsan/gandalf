#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

sudo apt-get update -y && sudo apt-get install -y ufw
sudo ufw --force enable || true
sudo ufw allow 22/tcp || true
sudo ufw allow 80/tcp  || true
sudo ufw allow 443/tcp || true
sudo ufw allow ${WG_PORT}/udp || true
log "[ufw] regler på plats"
