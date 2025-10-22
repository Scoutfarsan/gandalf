#!/usr/bin/env bash
# Var tolerant tills env är laddad
set -eo pipefail
set +u

. /opt/gandalf/lib/common.sh
load_env

# Nu kan vi vara strikta
set -u

export PIHOLE_SKIP_OS_CHECK=true
export USE_NETWORKMANAGER=false

apt-get update -y
apt-get install -y git curl procps sqlite3

if ! command -v pihole >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  git clone --depth=1 https://github.com/pi-hole/pi-hole.git "$tmp"
  mkdir -p /etc/pihole

  # Robust interface/IP-detektering utan awk
  IFACE="$(ip -o -4 route show to default | sed -E "s/.* dev ([^ ]+).*/\1/" | head -n1)"
  IP4="${PI_IP:-$(hostname -I | tr " " "\n" | head -n1)}"

  cat > /etc/pihole/setupVars.conf <<EOF
WEBPASSWORD=
PIHOLE_INTERFACE=${IFACE}
IPV4_ADDRESS=${IP4}/24
IPV6_ADDRESS=
DNS_BOGUS_PRIV=true
DNS_FQDN_REQUIRED=true
DNSMASQ_LISTENING=single
DNSSEC=false
REV_SERVER=false
BLOCKING_ENABLED=true
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
DNSMASQ_CONFIG=true
PIHOLE_DNS_1=127.0.0.1#5335
EOF

  # Obs: mappen har mellanslag → citera
  cd "$tmp/automated install"
  bash basic-install.sh --unattended
fi

systemctl enable --now pihole-FTL || true
echo "[m301-pihole] Installed/ensured"
