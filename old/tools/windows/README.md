# Windows-verktyg för Gandalf v6.43

Detta verktyg används för att förbereda ett Raspberry Pi SD-kort (BOOT-partitionen) för **zero-touch-installation** av projektet.

## Script

### `prepare-gandalf-boot.ps1`

PowerShell-skriptet gör följande:

- Identifierar BOOT-partitionen (FAT32) på SD-kortet
- Skapar mappar:
  - `boot-env/` (för icke-hemliga variabler)
  - `boot-secrets/` (för hemliga variabler)
- Lägger in default `.env`-filer (base, dhcp, vpn, logging, wifi)
- Lägger in default `secrets.env`-filer (core, ntfy, wifi)
- Säkerställer att en **Ed25519 SSH-nyckel** finns, och lägger till den i `ssh_authorized_keys`
- Kopierar in `age.key` om den finns lokalt (valfritt)
- Sätter upp miljön så att Pi:n kan köra `firstrun` automatiskt vid första boot

---

## Förberedelser

1. Se till att **OpenSSH Client** är installerat i Windows:
   - Inställningar → Appar → Valfria funktioner → Lägg till → *OpenSSH Client*
2. Ha ett SD-kort med Raspberry Pi OS, där BOOT-partitionen är monterad i Windows.
3. (Valfritt) Ha en `age.key` på plats om du vill återanvända befintliga age-nycklar.

---

## Användning

Kör från repo-roten i PowerShell (som admin om det behövs):

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\prepare-gandalf-boot.ps1 -ForceOverwrite
