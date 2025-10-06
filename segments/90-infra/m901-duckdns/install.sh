#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
if [ -z "${DUCKDNS_DOMAIN:-}" ] || [ -z "${DUCKDNS_TOKEN:-}" ]; then
  echo "[m901-duckdns] saknar DUCKDNS_* — hoppar."
  exit 0
fi
cat >/usr/local/sbin/duckdns-update.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o /var/log/duckdns.log -K -
SH
chmod 0755 /usr/local/sbin/duckdns-update.sh
cat >/etc/systemd/system/duckdns.service <<'SVC'
[Unit]
Description=DuckDNS updater
After=network-online.target
[Service]
Type=oneshot
Environment=DUCKDNS_DOMAIN=%i
ExecStart=/usr/local/sbin/duckdns-update.sh
SVC
cat >/etc/systemd/system/duckdns.timer <<'TMR'
[Unit]
Description=Run DuckDNS updater every 5 minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=duckdns.service
[Install]
WantedBy=timers.target
TMR
systemctl daemon-reload
systemctl enable --now duckdns.timer
echo "[m901-duckdns] Done."
