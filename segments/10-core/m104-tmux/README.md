# m104-tmux

Installerar **tmux** med en modern default-konfig och bekväma alias.

## Funktioner
- 256-färger, `mouse on`, lång historik (100k rader)
- Vi-läge i copy-mode, statusrad med host/användare/tid
- Smidiga split-bindningar: `|` (vertikal), `-` (horisontell)
- Navigering: `Ctrl+b` + `h/j/k/l`, resize med `H/J/K/L`
- Per-user `~/.tmux.conf` som inkluderar `/etc/gandalf/tmux.conf`
- Alias:
  - `tm` → attach till `main` eller skapa den om den saknas
  - `tmls` → lista sessioner

## Användning
- Start/attach: `tm`
- Skapa split: `Ctrl+b |` eller `Ctrl+b -`
- Detach: `Ctrl+b d`
- Ladda om konfig: `Ctrl+b r`

## Idempotens
Det är säkert att köra modulen flera gånger. Den skapar bara sessionen `main` om den saknas.
