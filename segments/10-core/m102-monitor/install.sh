#!/usr/bin/env bash
# m102-monitor/install.sh — v4.63.1 (2025-09-19)
# Installerar övervakningsverktyg inkl. GNU Screen och lägger en vettig default .screenrc

set -euo pipefail

echo "[m102-monitor] Installing monitor stack (screen)..."

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends screen

# Global default screenrc
install -d -m 0755 /etc/gandalf
cat >/etc/gandalf/screenrc <<'RC'
# /etc/gandalf/screenrc — Gandalf defaults
defscrollback 10000
defutf8 on
deflog on
logfile /var/log/screen/screen_%Y-%m-%d_%n.log
term screen-256color
startup_message off
vbell off
hardstatus alwayslastline
hardstatus string "%{= kw} [%H] %{-}%{= kG}%c %{-} | %{= kW}%w %{-} | %{= kB}%l %{-}"
caption always "%{= kG}%?%-Lw%?%{= kW}(%n:%t)%{-}%?%+Lw%?%=%{= kC}%Y-%m-%d %c"
bindkey -k k1 screen 0
bindkey -k k2 screen 1
bindkey -k k3 screen 2
bindkey -k k4 screen 3
RC

# Per-user default (för både pi och root om de finns)
for U in pi root; do
  HOME_DIR=$(getent passwd "$U" | cut -d: -f6 || true)
  if [ -n "${HOME_DIR:-}" ] && [ -d "$HOME_DIR" ]; then
    install -m 0700 -d "$HOME_DIR/.screen"
    install -m 0644 /etc/gandalf/screenrc "$HOME_DIR/.screenrc"
    chown -R "$U:$U" "$HOME_DIR/.screen" "$HOME_DIR/.screenrc"
  fi
done

# Loggkatalog
install -d -m 0755 /var/log/screen
chown root:adm /var/log/screen

echo "[m102-monitor] Done."
