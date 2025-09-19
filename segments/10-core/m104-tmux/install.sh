#!/usr/bin/env bash
# m104-tmux/install.sh — v4.63.2 (2025-09-19)
# Installerar tmux med en modern, behaglig default-konfiguration och bekväma alias.
# Idempotent: säkert att köra flera gånger.

set -euo pipefail

echo "[m104-tmux] Installing tmux and defaults..."

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends tmux

# Katalog för centrala konfigar
install -d -m 0755 /etc/gandalf

# Global tmux.conf
cat >/etc/gandalf/tmux.conf <<'TMUX'
# /etc/gandalf/tmux.conf — Gandalf defaults (v4.63.2)
set -g default-terminal "screen-256color"
set -g history-limit 100000
set -g mouse on
setw -g mode-keys vi
set -g status-interval 5
set -g status-position bottom
set -g status-left-length 40
set -g status-right-length 120
set -g status-bg default
set -g status-fg colour244
set -g status-left "#[bold]#H#[default] "
set -g status-right "%Y-%m-%d %H:%M | #[bold]#(whoami)#[default]"
set -g pane-border-format " #P #[bold]#T#[default] "
set -g pane-border-status top
set -g pane-active-border-style fg=colour10
set -g pane-border-style fg=colour241
bind r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded"
# Splits: | och -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
# Fönster/Paneler
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind H resize-pane -L 4
bind J resize-pane -D 2
bind K resize-pane -U 2
bind L resize-pane -R 4
# Snabb-namn
set-option -g automatic-rename on
set-window-option -g automatic-rename on
TMUX

# Lägg per-user ~/.tmux.conf (pekar på /etc/gandalf/tmux.conf) för pi och root om de finns
for U in pi root; do
  HOME_DIR=$(getent passwd "$U" | cut -d: -f6 || true)
  if [ -n "${HOME_DIR:-}" ] && [ -d "$HOME_DIR" ]; then
    install -d -m 0755 "$HOME_DIR"
    cat >"$HOME_DIR/.tmux.conf" <<'UCONF'
# Gandalf per-user tmux.conf (inkluderar global)
if-shell '[ -f /etc/gandalf/tmux.conf ]' "source-file /etc/gandalf/tmux.conf"
UCONF
    chown "$U:$U" "$HOME_DIR/.tmux.conf"
    chmod 0644 "$HOME_DIR/.tmux.conf"
  fi
done

# QoL-aliaser för alla användare
install -d -m 0755 /etc/profile.d
if ! grep -q "alias tm=" /etc/profile.d/gandalf-aliases.sh 2>/dev/null; then
  cat >>/etc/profile.d/gandalf-aliases.sh <<'AL'
# Gandalf aliases (tmux)
alias tm='tmux attach -t main 2>/dev/null || tmux new -s main'
alias tmls='tmux ls'
AL
  chmod 0644 /etc/profile.d/gandalf-aliases.sh
fi

# Skapa en initial session "main" om ingen finns (headless-vänligt)
if ! tmux has-session -t main 2>/dev/null; then
  tmux new-session -d -s main -n shell
fi

echo "[m104-tmux] Done."
