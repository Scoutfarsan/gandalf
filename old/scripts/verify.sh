#!/usr/bin/env bash
systemctl --no-pager --type=service | egrep 'pihole|unbound|wireguard|tailscale|caddy|promtail|loki' || true