#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
install -d -m 0755 "/etc/${REPO_NAME:-gandalf}/backups"
echo "[m501-backups] Done."
