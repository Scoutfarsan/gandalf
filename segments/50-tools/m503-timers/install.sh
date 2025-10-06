#!/usr/bin/env bash
set -euo pipefail
systemctl list-timers --all || true
echo "[m503-timers] Done."
