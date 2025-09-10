#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/scripts/lib/env.sh"

UP="$PIHOLE_UPSTREAM"
PASS="$(get PIHOLE_WEBPASSWORD "SäkertLösen123")"
IFACE="$PI_IFACE"
ADDR="${PI_IP}/24"

log "[30] Pi-hole install/konf"
sudo mkdir -p /etc/pihole

# seed setupVars (unattended)
if [ ! -f /etc/pihole/setupVars.conf ]; then
  sudo tee /etc/pihole/setupVars.conf >/dev/null <<EOF
PIHOLE_INTERFACE=${IFACE}
IPV4_ADDRESS=${ADDR}
IPV6_ADDRESS=
PIHOLE_DNS_1=${UP}
DNSMASQ_LISTENING=all
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
WEBPASSWORD=${PASS}
DHCP_ACTIVE=false
EOF
fi

if ! command -v pihole >/dev/null 2>&1; then
  sudo -E bash -lc 'export TERM=xterm DEBIAN_FRONTEND=noninteractive; curl -fsSL https://install.pi-hole.net | bash /dev/stdin --unattended'
fi

sudo pihole -a -p "$PASS" || true
sudo pihole -a setdns "$UP" --quiet || true

# Adlists styrs via variabel ADLISTS (komma-sep) om du vill override:a
_ADLISTS="$(get ADLISTS "")"
if [ -z "$_ADLISTS" ]; then
  _ADLISTS="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts,\
https://blocklistproject.github.io/Lists/ads.txt,\
https://blocklistproject.github.io/Lists/malware.txt,\
https://blocklistproject.github.io/Lists/phishing.txt,\
https://blocklistproject.github.io/Lists/abuse.txt,\
https://blocklistproject.github.io/Lists/porn.txt"
fi
IFS=',' read -r -a AL <<< "$_ADLISTS"
for url in "${AL[@]}"; do sudo pihole -g --addurl "$(echo "$url" | xargs)" || true; done
sudo pihole -g || true

# Regexlista kan override: REGEX_LIST (komma-sep)
_REGEX="$(get REGEX_LIST "")"
if [ -z "$_REGEX" ]; then
  _REGEX="([a-z0-9-]+\\.)*adult$,([a-z0-9-]+\\.)*porn$,([a-z0-9-]+\\.)*sex$"
fi
IFS=',' read -r -a RX <<< "$_REGEX"
for r in "${RX[@]}"; do sudo pihole --regex "$(echo "$r" | xargs)" || true; done

sudo systemctl restart pihole-FTL || true
log "[30] klar (upstream: $UP). DHCP förberett men INTE aktivt."
