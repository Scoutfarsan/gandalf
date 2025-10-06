# Gandalf — Zero-Touch Raspberry Pi för hemmanät (v6.43)

> **Affärsvärde:** en “set-and-forget” nätverksnod som stabiliserar DNS, hårdnar säkerheten, erbjuder VPN-åtkomst och central loggning – utan manuellt pill på Pi:n. **Mindre friktion, mer leverans.**

- **Målplattform:** Raspberry Pi 3B / 3B+ (fungerar även på nyare)
- **Huvudfunktioner:** Pi-hole, Unbound (DoT), WireGuard, Tailscale, Caddy, Loki/Promtail, autoheal, ntfy, Healthchecks
- **Koncept:** **Zero-touch** – förbered SD-kort i Windows → boota Pi → `firstrun` utför helinstall baserat på `.env`

---

## Innehåll

- [Arkitektur & flöde](#arkitektur--flöde)
- [Repo-struktur](#repo-struktur)
- [Förutsättningar](#förutsättningar)
- [Snabbstart (zero-touch)](#snabbstart-zero-touch)
- [Vad sker automatiskt vs manuellt](#vad-sker-automatiskt-vs-manuellt)
- [Manuell körning (firstrun & moduler)](#manuell-körning-firstrun--moduler)
- [Felsökning](#felsökning)
- [Drift & underhåll](#drift--underhåll)
- [Säkerhet & efterlevnad](#säkerhet--efterlevnad)
- [Nätverksdesign (referens)](#nätverksdesign-referens)
- [Versionshantering & releasepolicy](#versionshantering--releasepolicy)
- [FAQ](#faq)
- [Licens](#licens)

---

## Arkitektur & flöde

**Zero-touch pipeline:**
1. **Windows**: `tools/windows/prepare-gandalf-boot.ps1` skriver konfig till SD-kortets **BOOT**:
   - `boot-env/` (icke-hemligt) och `boot-secrets/` (hemligt)
   - `ssh_authorized_keys` från din Ed25519-nyckel
   - (Valfritt) `age.key` om du redan har en
2. **Pi bootar** → `boot-kit/firstrun.service` + `firstrun.sh`:
   - Kopierar BOOT-variabler till `/etc/gandalf/{env,secrets}`
   - Importerar/genererar **age.key** och dekrypterar `*.env.enc` om de finns
   - Klonar repo till `/opt/gandalf`
   - Kör `scripts/install.sh` som rullar alla **segment/moduler** i definierad ordning
3. **System klart** → verifieras via `scripts/verify.sh`

---

## Repo-struktur

```
.
├─ boot-kit/                 # firstrun för första boot (systemd service + script)
├─ lib/                      # gemensamma helpers (common.sh)
├─ scripts/                  # install/sanity/verify + sops helpers
├─ segments/                 # modulära paket i ordning
│  ├─ 10-core/               # nät, tmux/screen, wifi-failover, hosts
│  ├─ 20-security/           # ufw, fail2ban, ssh-hardening
│  ├─ 30-dns/                # pihole, unbound, adlists, dhcp
│  ├─ 40-vpn/                # wireguard, tailscale
│  ├─ 50-tools/              # backups, healthchecks, timers
│  ├─ 60-tls/                # caddy
│  ├─ 80-ops/                # loki, promtail, autoheal
│  └─ 90-infra/              # duckdns
├─ tools/
│  ├─ windows/
│  │  ├─ prepare-gandalf-boot.ps1   # BOOT-prep (robust ssh-keygen, v6.43)
│  │  └─ README.md
│  └─ linux/…                 # småhjälpare (t.ex. DHCP-render)
├─ env/                      # exempel på icke-hemliga env-filer (kan SOPS-krypteras .enc)
├─ secrets/                  # exempel på hemliga env-filer (kan SOPS-krypteras .enc)
├─ docs/                     # First10/OPS/SECURITY/NETWORK
├─ .sops.yaml                # SOPS/age policy (age recipients)
├─ Makefile                  # sops-setup, age-keygen, encrypt/decrypt, verify
└─ README.md                 # den här filen
```

**Segmentordning** hanteras via `.order` i varje segment. `scripts/install.sh` läser `.order` och kör varje moduls `install.sh`.

---

## Förutsättningar

- **Windows**: OpenSSH Client (Inställningar → Appar → Valfria funktioner)
- **SD-kort**: Raspberry Pi OS Lite (BOOT måste vara FAT32 med enhetsbokstav)
- **Nät**: Pi får IP på LAN (t.ex. 10.20.30.2), router når Internet
- **Router**: port-forward om WireGuard ska vara åtkomlig utifrån
- **GitHub**: repo publicerat (HTTPS eller SSH-klon)
- **Sekretess**: du **roterar** alla default-hemligheter innan skarp drift

---

## Snabbstart (zero-touch)

### 1) Förbered BOOT i Windows
Kör från repo-roten i PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\prepare-gandalf-boot.ps1 -ForceOverwrite
```

Scriptet gör:
- Skapar `boot-env/` + `boot-secrets/` och fyller grundläggande `.env`
- Säkerställer Ed25519-nyckel och skriver till `ssh_authorized_keys`
- Kopierar `age.key` om den finns lokalt (valfritt)

> **Viktigt:** Öppna och anpassa `boot-env/base.env` till ditt LAN (t.ex. `LAN_BASE`, `PI_IP`, `PI_HOSTNAME`). **Byt hemligheter** i `boot-secrets/*.env` innan du bootar.

### 2) Kopiera boot-kit
Kopiera hela **`boot-kit/`** till SD-kortets BOOT: `X:\boot-kit\`

### 3) Boosta Pi
Sätt i SD-kortet och boota. Följ loggar:
```bash
journalctl -u firstrun -f
```

### 4) Verifiera
```bash
sudo bash scripts/verify.sh
```

---

## Vad sker automatiskt vs manuellt

### ✅ Automatiskt
- Import/generering av **age.key** på Pi, och dekryptering av `*.env.enc` om de finns i repo:t
- Klon av repo till `/opt/gandalf`
- Körning av samtliga segment i definierad ordning
- Bas-setup: hostname, SSH-nyckel, UFW/Fail2ban, Pi-hole + Unbound, WireGuard + Tailscale, Caddy, Promtail + Loki, autoheal, DuckDNS (om konfigurerat)

### 🧩 Manuellt (ägarskap hos dig)
- **Roterar alla hemligheter** i `boot-secrets/*.env` (lösenord, tokens, API-nycklar)
- **Anpassar nätparametrar** i `boot-env/base.env` (LAN-subnet, gateway, Pi-IP)
- **Portforward/NAT** i router om WireGuard ska nås externt
- **Grafana Cloud** (om användning): sätt `GRAFANA_API_KEY`/`GRAFANA_USER`
- **ntfy** (om användning): egendefinierade topics/URL:er

---

## Manuell körning (firstrun & moduler)

### Köra om `firstrun`
> Användbart efter ändringar i `.env` eller för att återstarta flödet.

```bash
# Via systemd
sudo systemctl restart firstrun

# Eller direkt
sudo /boot/boot-kit/firstrun.sh
```

Följ loggar i realtid:
```bash
journalctl -u firstrun -f
```

### Köra enskilda moduler (smidig validering)
Exempel: kör om Unbound-modulen:
```bash
sudo bash /opt/gandalf/segments/30-dns/m302-unbound/install.sh
```

> **Tipset:** testkör modul för modul vid felsökning. Moduler är idempotenta i normalfallet (konfig skrivs om, tjänster startas om).

---

## Felsökning

**Inget händer på boot**
- Kontrollera att `boot-kit/firstrun.service` och `boot-kit/firstrun.sh` finns på **BOOT**
- Titta i logg:
  ```bash
  journalctl -b -u firstrun
  ```

**SSH funkar inte**
- Säkerställ att `boot-env/ssh_authorized_keys` skrevs av Windows-scriptet
- Verifiera att filen kopierades till `/etc/gandalf/env/` under `firstrun`

**DNS (Pi-hole/Unbound) strular**
- Status:
  ```bash
  systemctl status pihole-FTL unbound --no-pager
  ```
- Snabbtest:
  ```bash
  dig @127.0.0.1 -p 5335 example.com +short
  ```

**WireGuard uppe?**
- Status:
  ```bash
  systemctl status wg-quick@wg0 --no-pager
  wg show
  ```
- Router: verifiera port-forward till Pi (UDP `WG_PORT`, default 51820)

**Loki/Promtail**
- Test att Loki svarar:
  ```bash
  curl -fsS http://127.0.0.1:3100/ready
  ```
- Promtail:
  ```bash
  systemctl status promtail --no-pager
  ```

**Autoheal**
- Timer kör var 10:e minut. Manuell körning:
  ```bash
  sudo /usr/local/sbin/autoheal.sh
  journalctl -u autoheal -n 200
  ```

---

## Drift & underhåll

**Uppdatera repo på Pi:n**
```bash
cd /opt/gandalf
git pull
```

**Köra installationsflöde igen**
- Justera `.env` i `/etc/gandalf/{env,secrets}`
- Kör om vald modul eller hela `firstrun` (se ovan)

**SOPS/age-pipeline (om du vill kryptera env-filer i repo)**
```bash
make sops-setup
make age-keygen                     # skapar .keys/age/age.key + .pub
# lägg public key i .sops.yaml -> AGE_RECIPIENT_1_HERE
make encrypt EX=secrets/core.env    # ger secrets/core.env.enc
git add secrets/*.env.enc env/*.env.enc
git commit -m "chore(sops): encrypt env/secrets"
```
> **Policy:** committa **endast** `*.env.enc`. Lagra aldrig klartexthemligheter i Git.

---

## Säkerhet & efterlevnad

- **Roteringskrav:** byt alla default-hemligheter i `boot-secrets/*.env` före produktion.
- **SSH:** endast nyckelautentisering (lösenord avstängt i hårdningsmodul).
- **UFW/Fail2ban:** standard policy aktiverad, LAN/VPN whitelistas.
- **Loggar:** Promtail → Loki (lokalt, och valfritt till Grafana Cloud).
- **Notifieringar:** ntfy för install/autoheal, Healthchecks för liveness.
- **Compliance mindset:** ingen hemlighet i repo i klartext; använd SOPS/age vid behov.

---

## Nätverksdesign (referens)

**Exempel (standard i v6.43):**
- LAN: `10.20.30.0/24` (GW `.1`, Pi `.2`)
- WireGuard server: `10.20.35.1/24`
- Admin-VPN (framtid): `10.20.31.0/24`
- Gäst-VPN (framtid): `10.20.32.0/24`
- Andra sites: `10.20.40.0/24` +

> Justera i `boot-env/base.env`. Säkerställ att din router annonserar rätt routes om Tailscale-subnät används.

---

## Versionshantering & releasepolicy

- Tagga release:
  ```bash
  git tag v6.43
  git push --tags
  ```
- Dokumentera ändringar i `CHANGELOG.md` (rekommenderas).
- **Immutable mindset:** ändra inte historik i taggade versioner; bumpa version (`v6.44`) vid nya features.

---

## FAQ

**Q: Hur lång tid tar installationen?**  
**A:** Beror på Pi-modell/nät/paketcache. Följ loggar i `journalctl -u firstrun -f` tills verifieringen passerar.

**Q: Måste jag ha SOPS/age?**  
**A:** Nej. Zero-touch fungerar utan, men SOPS/age är rekommenderat om du vill lagra env-filer i Git med kryptering.

**Q: Kan jag köra enbart vissa funktioner (t.ex. bara DNS)?**  
**A:** Ja. Stäng av relevanta segment i `.order` eller låt modulerna hoppa installation baserat på env-flaggor.

**Q: Hur lägger jag till fler klienter i WireGuard?**  
**A:** Använd befintliga scripts/portal (om aktiverad), eller generera klientprofiler manuellt med `wg`.

---

## Licens

MIT (eller välj annan). Lägg till `LICENSE` i repo:t.
