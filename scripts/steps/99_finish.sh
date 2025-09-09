#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
sudo systemctl restart pihole-FTL || true; ntfy "finish" "Installation klar"
