# load_env stub

# QoL aliases för screen
if ! grep -q "alias scr=" /etc/profile.d/gandalf-aliases.sh 2>/dev/null; then
  cat >/etc/profile.d/gandalf-aliases.sh <<'AL'
alias scr='screen -DR'
alias scls='screen -ls'
AL
  chmod 0644 /etc/profile.d/gandalf-aliases.sh
fi
