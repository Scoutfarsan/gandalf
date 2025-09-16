#!/usr/bin/env bash
set -euo pipefail
DEST="${BACKUP_DIR:-/etc/${REPO_NAME}/backups}"
mkdir -p "$DEST"
date_tag=$(date +%Y%m%d-%H%M%S)
tar czf "${DEST}/backup-${date_tag}.tgz" /etc/wireguard /etc/dnsmasq.d /etc/caddy 2>/dev/null || true
echo "[backup] Saved ${DEST}/backup-${date_tag}.tgz"
