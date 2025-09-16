#!/usr/bin/env bash
set -euo pipefail
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; NC="\033[0m"
ok(){ echo -e "${GREEN}[OK]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
die(){ echo -e "${RED}[ERR]${NC} $*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="/etc/${REPO_NAME:-gandalf}"

# Seed env from samples if missing
mkdir -p "$ENV_DIR"
[[ -f "$ENV_DIR/.env" ]] || cp "${REPO_ROOT}/scripts/env/.env.sample" "$ENV_DIR/.env"
[[ -f "$ENV_DIR/secrets.env" ]] || (cp "${REPO_ROOT}/scripts/env/secrets.env.sample" "$ENV_DIR/secrets.env" && chmod 600 "$ENV_DIR/secrets.env")

# Load env
# shellcheck disable=SC1090
source "$ENV_DIR/.env"
# shellcheck disable=SC1090
source "$ENV_DIR/secrets.env" || true
ENV_DIR="/etc/${REPO_NAME}"

sudo -n true 2>/dev/null || die "Kör med sudo: sudo ./scripts/install.sh"

# Base packages
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y ufw fail2ban wireguard resolvconf unbound caddy sqlite3 jq curl git iptables iproute2 dnsutils dnsmasq

# Common dirs
mkdir -p "/var/lib/${REPO_NAME}" "/etc/wireguard" "/etc/caddy" "/etc/dnsmasq.d" "${BACKUP_DIR:-/etc/${REPO_NAME}/backups}"

# Module runner
run_module(){
  local flag="$1"; local path="$2"
  local enabled="${!flag:-0}"
  if [[ "$enabled" != "1" ]]; then
    warn "Skippar modul ${path} (flagga ${flag}=0)"; return 0
  fi
  local script="${REPO_ROOT}/modules/${path}/install.sh"
  if [[ -x "$script" ]]; then
    ok "Kör modul ${path}"
    bash "$script"
  else
    warn "Saknar körbart installscript: ${script}"
  fi
}

# Modules (deterministic order)
run_module MODULE_security  "70-security"
run_module MODULE_caddy     "60-caddy"
run_module MODULE_wireguard "50-wireguard"
run_module MODULE_dhcp      "35-dhcp"
run_module MODULE_autoheal  "80-autoheal"

# Ensure base services
systemctl enable --now fail2ban || true
systemctl enable --now unbound || true
systemctl enable --now caddy || true
systemctl enable --now wg-quick@${WG_INTERFACE:-wg0} || true

# UFW baseline
ufw allow 53 || true
ufw allow 80,443/tcp || true
ufw allow 51820/udp || true
ufw deny 8088/tcp || true
ufw --force enable || true

ok "Install klart. Verifiera: WG, Caddy/TLS, Unbound, DHCP (staged/aktiv), Autoheal."
