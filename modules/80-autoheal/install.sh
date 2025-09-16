#!/usr/bin/env bash
set -euo pipefail
install -m 700 "/opt/${REPO_NAME}/scripts/autoheal.sh" /usr/local/sbin/autoheal.sh
install -m 644 "$(dirname "$0")/autoheal.service" /etc/systemd/system/autoheal.service
install -m 644 "$(dirname "$0")/autoheal.timer" /etc/systemd/system/autoheal.timer
systemctl daemon-reload
systemctl enable --now autoheal.timer
