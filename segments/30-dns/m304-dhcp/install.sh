#!/usr/bin/env bash
set -euo pipefail
ROOT=/opt/gandalf
mkdir -p /etc/dnsmasq.d
cp -f "C:\Users\parca1\Desktop\gandalf-v6.45-complete/env/dhcp/99-gandalf-dhcp.conf" /etc/dnsmasq.d/99-gandalf-dhcp.conf
bash "C:\Users\parca1\Desktop\gandalf-v6.45-complete/scripts/dhcp/build-static-from-csv.sh" "C:\Users\parca1\Desktop\gandalf-v6.45-complete/env/dhcp-static.csv" "/etc/dnsmasq.d/99-gandalf-dhcp-static.conf"
systemctl restart pihole-FTL || true