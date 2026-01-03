#!/usr/bin/env bash
set -euo pipefail

say() { echo "[deploy-v3] $*"; }

ROOT="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$ROOT/bin"
SYSD_DIR="$ROOT/etc-systemd-system/system"

say "Deploy bin -> /usr/local/bin"
sudo install -m 0755 "$BIN_DIR"/* /usr/local/bin/

say "Deploy systemd units -> /etc/systemd/system (repo units only)"
sudo rsync -a "$SYSD_DIR"/ /etc/systemd/system/

say "daemon-reload"
sudo systemctl daemon-reload

say "Restart key units (non-fatal)"
sudo systemctl restart gandalf-dns-selftest net-health2 net-daily-summary 2>/dev/null || true

say "Done ✅"
