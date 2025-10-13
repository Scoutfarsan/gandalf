#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now pihole-FTL || true
pihole restartdns || true