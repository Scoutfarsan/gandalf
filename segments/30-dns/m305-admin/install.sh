#!/usr/bin/env bash
set -euo pipefail
USER_VAL=""; HASH_VAL=""
if [ -r /opt/gandalf/env/base.env ]; then
  set +u; . /opt/gandalf/env/base.env; set -u
  USER_VAL="${PIHOLE_ADMIN_USER:-}"; HASH_VAL="${PIHOLE_ADMIN_HASH:-}"
fi
install -d /etc/caddy
NEW="/etc/caddy/Caddyfile.new"; CUR="/etc/caddy/Caddyfile"
cat >"$NEW" <<EOF
:80 {
    respond /health "gandalf ok" 200
    @admin_no_slash path /admin
    redir @admin_no_slash /admin/ 308
    handle /admin* {
$( if [ -n "$USER_VAL" ] && [ -n "$HASH_VAL" ]; then printf '        basicauth /* {\n            %s %s\n        }\n' "$USER_VAL" "$HASH_VAL"; fi )
        reverse_proxy 127.0.0.1:8080
    }
}
EOF
umask 022; FMT="$(mktemp)"; caddy fmt "$NEW" >"$FMT"; install -o root -g root -m 0644 "$FMT" "$NEW"; rm -f "$FMT"
caddy validate --config "$NEW" --adapter caddyfile >/dev/null
install -o root -g root -m 0755 -d /etc/caddy
install -o root -g root -m 0644 "$NEW" "$CUR"; rm -f "$NEW"
# RELOAD FLYTTAS UTANFÖR (kör manuellt efter patchen)
echo "[m305-admin] Klar: /admin proxas och (om satt) skyddas med BasicAuth."
