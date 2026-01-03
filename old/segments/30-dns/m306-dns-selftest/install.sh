#!/usr/bin/env bash
set -euo pipefail
IP="127.0.0.1"; OK=0
curl -fsS "http://$IP/health" | grep -q "gandalf ok" && echo "[selftest] Caddy: OK" || { echo "[selftest] Caddy: FAIL"; OK=1; }
dig +time=2 +retry=1 @${IP} pi.hole A     | grep -q "NOERROR" && echo "[selftest] Pi-hole: OK" || { echo "[selftest] Pi-hole: FAIL"; OK=1; }
dig +time=3 +retry=1 @${IP} example.com A | grep -q "NOERROR" && echo "[selftest] Unbound chain: OK" || { echo "[selftest] Unbound chain: FAIL"; OK=1; }
BLOCK_TEST="doubleclick.net"
if dig +time=2 +retry=1 @${IP} $BLOCK_TEST A | grep -q "0.0.0.0"; then echo "[selftest] Block: OK ($BLOCK_TEST)"; else echo "[selftest] Block: WARN ($BLOCK_TEST ej 0.0.0.0)"; fi
exit $OK
