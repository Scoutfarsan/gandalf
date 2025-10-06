#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh 2>/dev/null || true; load_env 2>/dev/null || true
install -d -m 0755 /etc/autoheal /usr/local/sbin
cat >/etc/autoheal/autoheal.conf <<'CONF'
PING_TARGETS="1.1.1.1 8.8.8.8"
PING_COUNT=2
DISK_FS="/"
DISK_WARN=80
DISK_CRIT=90
TEMP_WARN=70
TEMP_CRIT=80
SERVICES="pihole-FTL unbound tailscaled wg-quick@wg0 promtail loki"
NTFY_URL="${NTFY_RUNTIME_URL:-}"
HC_UUID="${HC_RUNTIME_UUID:-}"
HC_BASE="https://hc-ping.com"
CONF
cat >/usr/local/sbin/autoheal.sh <<'AGENT'
#!/usr/bin/env bash
set -euo pipefail
CFG="/etc/autoheal/autoheal.conf"
[ -f "$CFG" ] && . "$CFG"
notify(){ local msg="$1"; local title="autoheal@$(hostname)"; [ -n "${NTFY_URL:-}" ] && curl -fsS -H "Title: ${title}" -H "Tags: wrench" -d "$msg" "$NTFY_URL" >/dev/null 2>&1 || true; }
hc_ping(){ [ -n "${HC_UUID:-}" ] && curl -fsS "${HC_BASE}/${HC_UUID}$1" >/dev/null 2>&1 || true; }
hc_ping "" || true
for h in $PING_TARGETS; do ping -c ${PING_COUNT:-2} -W 2 "$h" >/dev/null 2>&1 || notify "Ping fail $h"; done
usage=$(df -P "${DISK_FS:-/}" | awk 'NR==2{print $5}' | tr -d '%')
[ "${usage:-0}" -ge "${DISK_CRIT:-90}" ] && notify "DISK CRIT ${DISK_FS:-/} ${usage}%" || { [ "${usage:-0}" -ge "${DISK_WARN:-80}" ] && notify "DISK WARN ${DISK_FS:-/} ${usage}%"; }
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then t=$(( $(cat /sys/class/thermal/thermal_zone0/temp)/1000 )); [ "$t" -ge "${TEMP_CRIT:-80}" ] && notify "TEMP CRIT ${t}C" || { [ "$t" -ge "${TEMP_WARN:-70}" ] && notify "TEMP WARN ${t}C"; }; fi
for s in $SERVICES; do systemctl is-active --quiet "$s" || { systemctl restart "$s" || true; sleep 2; systemctl is-active --quiet "$s" && notify "Restart OK $s" || notify "Restart FAIL $s"; }; done
hc_ping "/0" || true
AGENT
chmod 0755 /usr/local/sbin/autoheal.sh
cat >/etc/systemd/system/autoheal.service <<'SVC'
[Unit]
Description=Autoheal periodic agent
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/autoheal.sh
SVC
cat >/etc/systemd/system/autoheal.timer <<'TMR'
[Unit]
Description=Run autoheal every 10 minutes
[Timer]
OnBootSec=3min
OnUnitActiveSec=10min
AccuracySec=1min
Unit=autoheal.service
[Install]
WantedBy=timers.target
TMR
systemctl daemon-reload
systemctl enable --now autoheal.timer
