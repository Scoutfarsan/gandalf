#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

# Lyssnar-adress:port för Unbound kan styras i .env (default 127.0.0.1#5335)
LISTEN="${UNBOUND_LISTEN:-127.0.0.1#5335}"
ADDR="${LISTEN%%#*}"
PORT="${LISTEN##*#}"

log "Konfigurerar Unbound (${ADDR}:${PORT})"

# Säkerställ paketet
req unbound

# Skapa huvudkonfig som inkluderar vår conf.d-fil (idempotent overwrite)
echo 'include: "/etc/unbound/unbound.conf.d/pi-hole.conf"' | sudo tee /etc/unbound/unbound.conf >/dev/null

# Skapa conf.d-katalogen
sudo mkdir -p /etc/unbound/unbound.conf.d

# Skriv pi-hole.conf utifrån env
sudo tee /etc/unbound/unbound.conf.d/pi-hole.conf >/dev/null <<EOF
server:
    verbosity: 0
    interface: ${ADDR}
    port: ${PORT}
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    so-reuseport: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    qname-minimisation: ${UNBOUND_QNAME_MINIMIZATION:-yes}
    num-threads: 1
    cache-min-ttl: ${UNBOUND_CACHE_MIN_TTL:-120}
    cache-max-ttl: ${UNBOUND_CACHE_MAX_TTL:-86400}
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    do-not-query-localhost: no
EOF

# (Re)generera trust anchor för att undvika "presented twice"-fel
sudo rm -f /var/lib/unbound/root.key
if command -v unbound-anchor >/dev/null 2>&1; then
  sudo unbound-anchor -a /var/lib/unbound/root.key
else
  # vissa builds lägger unbound-anchor under /usr/sbin
  if [ -x /usr/sbin/unbound-anchor ]; then
    sudo /usr/sbin/unbound-anchor -a /var/lib/unbound/root.key
  else
    # fallback: installera om paketet (borde inte behövas men skadar inte)
    sudo apt-get update -y && sudo apt-get install -y unbound
    sudo unbound-anchor -a /var/lib/unbound/root.key
  fi
fi

# Sätt ägare om användaren "unbound" finns
if id unbound >/dev/null 2>&1; then
  sudo chown unbound:unbound /var/lib/unbound/root.key
fi
sudo chmod 644 /var/lib/unbound/root.key

# Validera konfig och starta
sudo unbound-checkconf
sudo systemctl enable --now unbound
sudo systemctl restart unbound

# Snabb status till logg
if systemctl is-active --quiet unbound; then
  log "Unbound är igång på ${ADDR}:${PORT}"
  ntfy "unbound-ok" "Unbound igång på ${ADDR}:${PORT}"
else
  log "Unbound misslyckades starta – kolla journalctl -xeu unbound.service"
  ntfy "unbound-fail" "Unbound kunde inte startas – se journal"
  exit 1
fi
