# m102-monitor
Installerar GNU Screen och lägger en default-konfig.

## Användning
- Start/attach: `screen -DR` (alias: `scr`)
- Lista sessioner: `screen -ls`
- Detach: `Ctrl+a d`
- Loggar: `/var/log/screen/`

Konfig:
- Global: `/etc/gandalf/screenrc`
- Per user: `~/.screenrc` (skapas vid installation)
