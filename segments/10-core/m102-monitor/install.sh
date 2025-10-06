#!/usr/bin/env bash
set -euo pipefail
apt-get update -y && apt-get install -y --no-install-recommends screen
install -d -m 0755 /etc/gandalf /var/log/screen
cat >/etc/gandalf/screenrc <<'RC'
defscrollback 10000
defutf8 on
deflog on
logfile /var/log/screen/screen_%Y-%m-%d_%n.log
term screen-256color
startup_message off
RC
for U in pi root; do
  HOME_DIR=$(getent passwd "$U" | cut -d: -f6 || true)
  if [ -n "$HOME_DIR" ] && [ -d "$HOME_DIR" ]; then
    install -m 0700 -d "$HOME_DIR/.screen"
    install -m 0644 /etc/gandalf/screenrc "$HOME_DIR/.screenrc"
    chown -R "$U:$U" "$HOME_DIR/.screen" "$HOME_DIR/.screenrc"
  fi
done
echo 'alias scr="screen -DR"; alias scls="screen -ls"' >>/etc/profile.d/gandalf-aliases.sh
chmod 0644 /etc/profile.d/gandalf-aliases.sh
echo "[m102-monitor] Done."
