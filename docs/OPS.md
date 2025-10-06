# OPS
- systemctl status pihole-FTL unbound wg-quick@wg0 tailscaled caddy loki promtail autoheal.timer
- journalctl -u promtail -n 200
- curl -fsS http://127.0.0.1:3100/ready
