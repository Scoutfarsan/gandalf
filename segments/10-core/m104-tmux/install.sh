#!/usr/bin/env bash
set -euo pipefail
apt-get update -y && apt-get install -y --no-install-recommends tmux
install -d -m 0755 /etc/gandalf
cat >/etc/gandalf/tmux.conf <<'TMUX'
set -g default-terminal "screen-256color"
set -g history-limit 100000
set -g mouse on
setw -g mode-keys vi
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
bind r source-file ~/.tmux.conf \; display-message "reloaded"
TMUX
for U in pi root; do
  HOME_DIR=$(getent passwd "$U" | cut -d: -f6 || true)
  [ -n "$HOME_DIR" ] && [ -d "$HOME_DIR" ] && echo 'if-shell "[ -f /etc/gandalf/tmux.conf ]" "source-file /etc/gandalf/tmux.conf"' >"$HOME_DIR/.tmux.conf" && chown "$U:$U" "$HOME_DIR/.tmux.conf"
done
echo 'alias tm="tmux attach -t main 2>/dev/null || tmux new -s main"' >/etc/profile.d/gandalf-aliases.sh
chmod 0644 /etc/profile.d/gandalf-aliases.sh
if ! tmux has-session -t main 2>/dev/null; then tmux new-session -d -s main -n shell; fi
echo "[m104-tmux] Done."
