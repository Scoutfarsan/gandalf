#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y sqlite3 >/dev/null

DB=/etc/pihole/gravity.db
if [ ! -f "$DB" ]; then
  echo "[m303-dnsfilters] Pi-hole ej installerat ännu – hoppar."
  exit 0
fi

# Escapa enkla citationstecken för SQLite (enkel och robust)
esc() { printf "%s" "$1" | sed "s/'/''/g"; }

add_entry() {
  local url="$1"; local comment="${2:-$1}"
  [ -n "$url" ] || return 0
  local u c; u=$(esc "$url"); c=$(esc "$comment")
  sqlite3 "$DB" "INSERT OR IGNORE INTO adlist (address, enabled, comment) VALUES ('$u',1,'$c');"
}

# Baslistor
add_entry "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" "StevenBlack (base)"
add_entry "https://blocklistproject.github.io/Lists/alt-version/abuse-nl.txt" "BLP Abuse"
add_entry "https://blocklistproject.github.io/Lists/alt-version/porn-nl.txt"  "BLP Porn"
add_entry "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn/hosts" "StevenBlack gambling+porn"

# Gravity-uppdatering
if command -v pihole >/dev/null 2>&1; then
  if [ "$(id -u)" -ne 0 ]; then sudo pihole -g || true; else pihole -g || true; fi
fi

echo "[m303-dnsfilters] Klar."
