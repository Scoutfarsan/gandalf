#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; . "$ROOT_DIR/scripts/lib/env.sh"

BACKUP_DIR="$(get BACKUP_DIR "/etc/${REPO_NAME}/backups")"
RET_DAYS="$(get BACKUP_RETENTION_DAYS "30")"
sudo install -d -m 0750 "$BACKUP_DIR"

sudo tee /usr/local/sbin/${REPO_NAME}-backup >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd 2>/dev/null || echo /opt/gandalf)"
. "$ROOT_DIR/scripts/lib/env.sh"

TS=$(date +%F_%H%M%S)
OUT="${BACKUP_DIR}/${REPO_NAME}_${TS}.tar.gz"
sudo tar -czf "$OUT" \
  /etc/pihole /etc/dnsmasq.d /etc/unbound \
  /etc/wireguard /var/lib/wg-portal \
  "$ROOT_DIR/.env" "$ROOT_DIR/secrets.env" 2>/dev/null || true
find "$BACKUP_DIR" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete || true
echo "$OUT"
EOF
sudo chmod +x /usr/local/sbin/${REPO_NAME}-backup

sudo tee /etc/systemd/system/${REPO_NAME}-backup.service >/dev/null <<EOF
[Unit]
Description=${REPO_NAME} config backup
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/${REPO_NAME}-backup
EOF

sudo tee /etc/systemd/system/${REPO_NAME}-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily backup @ 03:30
[Timer]
OnCalendar=*-*-* 03:30:00
Unit=gandalf-backup.service
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ${REPO_NAME}-backup.timer
log "[backups] daily 03:30 till ${BACKUP_DIR} (retention ${RET_DAYS}d)"
