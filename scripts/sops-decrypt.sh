#!/usr/bin/env bash
# scripts/sops-decrypt.sh — v6.43
set -euo pipefail
KEY_DIR="/etc/gandalf/keys/age"
AGE_KEY="$KEY_DIR/age.key"
DST_ENV="/etc/gandalf/env"
DST_SEC="/etc/gandalf/secrets"
install -d -m 0755 "$KEY_DIR" "$DST_ENV" "$DST_SEC"

if [ ! -f "$AGE_KEY" ]; then
  echo "[sops-decrypt] age.key saknas i $KEY_DIR — hoppar över."
  exit 0
fi
export SOPS_AGE_KEY_FILE="$AGE_KEY"

shopt -s nullglob
for f in secrets/*.env.enc env/*.env.enc; do
  base="$(basename "$f" .enc)"
  case "$f" in
    secrets/*) out="$DST_SEC/$base" ;;
    env/*)     out="$DST_ENV/$base" ;;
  esac
  echo "[sops-decrypt] $f -> $out"
  sops --decrypt --input-type dotenv --output-type dotenv "$f" > "$out"
  chmod 600 "$out"
done
echo "[sops-decrypt] klart."
