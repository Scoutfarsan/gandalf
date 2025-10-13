# Gandalf v6.46 — Zero-Touch (baseline)

1) Fyll **secrets/\*.env** och ev. **env/\*.env**.
2) För zero-touch från SD: lägg oot-kit/ på bootpartitionen under /boot/firmware/boot-kit/, enable irstrun.service.
3) Pi:n klonar detta repo till **/opt/gandalf** och kör **scripts/install.sh**.
Loggar: /var/log/gandalf-firstrun.log, /var/log/gandalf-install.log.
