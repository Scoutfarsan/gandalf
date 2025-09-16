#!/usr/bin/env bash
set -euo pipefail
# Load env for flags
if [[ -f /etc/${REPO_NAME}/.env ]]; then source /etc/${REPO_NAME}/.env; fi
if [[ -f /etc/${REPO_NAME}/secrets.env ]]; then source /etc/${REPO_NAME}/secrets.env; fi
DHCP_ACTIVATE="${DHCP_ACTIVATE:-0}"

install -m 644 "$(dirname "$0")/02-dhcp-scopes.conf" /etc/dnsmasq.d/02-dhcp-scopes.conf

# Behåll befintlig hosts.conf om den redan finns
if [[ ! -f /etc/dnsmasq.d/04-dhcp-hosts.conf ]]; then
  install -m 644 "$(dirname "$0")/04-dhcp-hosts.conf.sample" /etc/dnsmasq.d/04-dhcp-hosts.conf
  echo "[dhcp] La in sample för 04-dhcp-hosts.conf – fyll MAC/IP/namn före aktivering."
fi

if [[ "$DHCP_ACTIVATE" == "1" ]]; then
  if systemctl is-active --quiet pihole-FTL; then
    systemctl restart pihole-FTL
  else
    systemctl restart dnsmasq
  fi
  echo "[dhcp] Aktiverat DHCP-konfiguration (service restartad)."
else
  echo "[dhcp] Staged – ingen restart (DHCP_ACTIVATE=0)."
fi
