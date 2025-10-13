#!/usr/bin/env bash
set -euo pipefail
. /opt/gandalf/lib/common.sh; load_env
hostnamectl set-hostname "\" || true