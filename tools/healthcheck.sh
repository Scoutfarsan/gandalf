#!/usr/bin/env bash
set -euo pipefail
if [[ -n "${HC_RUNTIME_UUID:-}" ]]; then
  curl -fsS "https://hc-ping.com/${HC_RUNTIME_UUID}" -m 10 || true
fi
