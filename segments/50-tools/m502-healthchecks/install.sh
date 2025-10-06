#!/usr/bin/env bash
set -euo pipefail; . /opt/gandalf/lib/common.sh; load_env
if [ -n "${HC_RUNTIME_UUID:-}" ]; then curl -fsS "https://hc-ping.com/${HC_RUNTIME_UUID}/start" || true; fi
if [ -n "${HC_RUNTIME_UUID:-}" ]; then curl -fsS "https://hc-ping.com/${HC_RUNTIME_UUID}/0" || true; fi
echo "[m502-healthchecks] Done."
