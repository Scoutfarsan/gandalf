#!/usr/bin/env bash
# scripts/sops-setup.sh — v6.43
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y age curl ca-certificates
if ! command -v sops >/dev/null 2>&1; then
  ARCH="$(dpkg --print-architecture)"
  URL="https://github.com/getsops/sops/releases/latest/download/sops-linux-${ARCH}"
  curl -fsSL "$URL" -o /usr/local/bin/sops
  chmod +x /usr/local/bin/sops
fi
echo "sops: $(sops --version)"
