# C.0 – DNS i skuggläge (pilot / shadow)

## Mål
Kör Gandalf som DNS för en liten kontrollerad mängd klienter, utan att byta DHCP/DNS för hela nätet.
Telia F1 fortsätter vara “source of truth” för DHCP och majoriteten av klienterna.

## Vad du får ut
- Riktig trafik i Pi-hole (queries, block, allowlist-behov)
- Stabilitetsdata (FTL, upstream, latency)
- Låg risk: endast pilot-klienten påverkas

## Rekommenderad metod: Pilot-klient
1. Välj en klient (t.ex. din laptop).
2. Ställ in DNS manuellt på klienten till Gandalf IP (ex: 192.168.100.229).
3. Lämna gateway/övrigt som vanligt (Telia F1).
4. Verifiera:
   - Surfa fungerar
   - Pi-hole query log fylls
   - Block sker (om listor/regex finns)

## Snabba verifieringar
### Testa resolution via Gandalf
- `dig @<GANDALF_IP> google.com +short`
- `dig @<GANDALF_IP> cloudflare.com +short`

### Testa block (om du har relevant lista)
- `dig @<GANDALF_IP> doubleclick.net +short`

## Operativ rutin (rekommenderad)
- Dag 1–2: 1 pilot-klient
- Dag 3–4: 2 pilot-klienter
- När stabilt: nästa steg blir att planera cutover (DHCP/DNS i nätet), men först när du har datapunkter.

## Smoketest
Det finns ett script: `gandalf-c0-smoketest` som:
- gör DNS-resolve via Gandalf
- kollar att FTL är igång
- skickar status via ntfy (om installerat)

Kör: `sudo /usr/local/bin/gandalf-c0-smoketest`
