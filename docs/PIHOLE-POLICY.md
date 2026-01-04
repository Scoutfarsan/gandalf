# Pi-hole Policy-as-Code (Gandalf)

## Struktur
All policy ligger i `pihole-rules/` i repo.

- `groups.txt` – Pi-hole grupper (motsvarar DHCP-grupper)
- `clients.csv` – klient → grupp (IP/MAC/hostname)
- `adlists.txt` – blocklistor
- `allow_regex_always.txt` – ALLTID öppet (kritiska tjänster)
- `block_regex_global.txt` – alltid blockat för alla
- `block_regex_except_alexander.txt` – blockat för alla UTOM Alexander
- `blockall_regex.txt` – “internet off”-regex som togglas via schema
- `allow_regex_apps.txt` – valfri allowlist för streaming/gaming (aktiveras vid behov)

## Apply
På Gandalf:
- Manuell apply: `sudo /usr/local/bin/pihole-policy-apply`
- Auto: `pihole-policy-apply.timer` (dagligen)

## Tidsstyrning (internet OFF)
- `pihole-blockall-on.timer` (barn+gäster: på)
- `pihole-blockall-off.timer` (barn+gäster: av)

**Always-Allow** är whitelistad, så BankID/Krisinfo/Verisure m.fl. fungerar även under blockall.

## Uppdatera regler
1) Ändra filer i `pihole-rules/`
2) `git commit -am "policy: update"`
3) `git push`
4) Gandalf hämtar och applicerar automatiskt nästa körning, eller kör manuellt:
   `sudo /usr/local/bin/pihole-policy-apply`
