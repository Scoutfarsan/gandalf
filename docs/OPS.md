# Gandalf Ops – Runbook

## Viktiga kommandon
### Status (snabb driftpanel)
- `sudo /usr/local/bin/gandalf-ops-status`

### Pi-hole uppdatering (safe wrapper)
- Timer: `pihole-safe-update.timer`
- Manuell (force): `sudo FORCE=1 /usr/local/bin/pihole-safe-update.sh`

### Pi-hole gravity (listor/regex/allow/deny byggs)
- Timer: `pihole-gravity-refresh.timer`
- Manuell (force): `sudo FORCE=1 /usr/local/bin/pihole-gravity-refresh.sh`

### Pi-hole rules sync (repo -> Pi-hole)
- Timer: `pihole-rules-sync.timer`
- Manuell (force): `sudo FORCE=1 /usr/local/bin/pihole-rules-sync.sh`

### APT safe update (kontrollerad)
- Timer: `apt-safe-update.timer`
- Manuell (force): `sudo FORCE=1 /usr/local/bin/apt-safe-update.sh`

### APT network maintenance (månatlig “större” uppdatering)
- Kommando: `sudo apt-network-maintenance`
- Timer: `apt-network-maintenance.timer` (månatlig 05:30)

## Loggar
- APT: `/var/log/apt-safe-update.log`
- Pi-hole update: `/var/log/pihole-safe-update.log`
- Gravity: `/var/log/pihole-gravity-refresh.log`
- Rules sync: `/var/log/pihole-rules-sync.log`

## Vanliga checks
- Timers: `systemctl list-timers --all | egrep 'apt-|pihole-|gandalf-|net-'`
- Failures: `systemctl --failed`
- Pi-hole status: `pihole status`
- FTL: `systemctl status pihole-FTL --no-pager -l`
- DNS test: `dig @127.0.0.1 google.com +short`

## Rollback-tänk (pragmatisk)
- Eftersom Telia F1 fortfarande håller DHCP/DNS för majoriteten (innan cutover) är rollback oftast:
  - backa piloten (ställ DNS tillbaka på klienten)
  - disable timers vid behov:
    - `sudo systemctl disable --now pihole-rules-sync.timer`
    - `sudo systemctl disable --now pihole-gravity-refresh.timer`
    - `sudo systemctl disable --now apt-safe-update.timer`

