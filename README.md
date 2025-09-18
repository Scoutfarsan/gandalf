# Gandalf — Zero-Touch Pi Server

Detta repo innehåller en **zero-touch installation** för min Raspberry Pi, med fokus på:
- Pi-hole + Unbound + DNS-filtering
- VPN (WireGuard + Tailscale)
- Säkerhet (UFW + Fail2ban med LAN-whitelist)
- Automatisering (ntfy, autoheal, backups, healthchecks, timers)
- Loggning (Loki, Promtail, Grafana Cloud integration)
- Wi-Fi-failover (alltid aktiv, 3 SSID i prioriteringsordning)

## 🚀 Kom igång (Zero-Touch)

1. **Förbered SD-kortet**
   - Flasha Raspberry Pi OS Lite (64-bit).
   - Kopiera in `boot-kit/` från detta repo till **BOOT-partitionen**.
   - Kör `tools/windows/prepare-gandalf-boot.ps1` på din Windows-dator:
     - Skapar mapparna `boot-env/` och `boot-secrets/` på SD-kortet.
     - Fyll i dina SSID, lösenord, API-nycklar, etc.
2. **Boota Pi:n**
   - Sätt i SD-kortet och starta upp.
   - `firstrun.sh` klonar detta repo och triggar `scripts/install.sh`.
3. **Följ installationen**
   - Status skickas till din **ntfy-kanal**.
   - Du kan även kolla lokalt i loggen: `/var/log/gandalf-install.log`.

## 📂 Repo-struktur
   - `boot-kit/`                *# Init-script på BOOT-partitionen*
   - `boot-env-templates/`      *# Exempel på .env-filer*
   - `boot-secrets-templates/`  *# Exempel på secrets-filer*
   - `lib/`                     *# Hjälpscript (common.sh)*
   - `scripts/`                 *# Installationslogik (install.sh, bootstrap-env.sh)*
   - `segments/`                *# Moduler (10-core, 20-dns, 30-lan, 60-vpn, 70-security, 80-ops, 90-infra)*
   - `tools/`                   *# Extra verktyg (systemd-unit, Windows helper)*
   - `docs/`                    *# CHANGELOG, NETWORK, LOGGING, KEYS*

## 🛡 Säkerhet
- Alla känsliga nycklar ligger i `/etc/gandalf/secrets`.
- `boot-secrets/` på SD-kortet raderas automatiskt efter första boot.

## 📝 Versionshantering
- Aktuell version: **v4.63 full-fat**
- Se `docs/CHANGELOG.md` för historik.
