#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh; load_env
grep -q "\ \" /etc/hosts || echo "\ \" | sudo tee -a /etc/hosts >/dev/null