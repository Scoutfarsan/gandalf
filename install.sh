#!/usr/bin/env bash
set -euo pipefail

# Ladda env tidigt (från /boot vid första boot)
[ -f /boot/firmware/.env ] && { set -a; . /boot/firmware/.env; set +a; }

# Defaults
REPO_OWNER="${REPO_OWNER:-ditt_githubkonto}"
REPO_NAME="${REPO_NAME:-pihole}"
REPO_URL_DEFAULT="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
REPO_URL="${REPO_URL:-$REPO_URL_DEFAULT}"
INSTALL_DIR="${INSTALL_DIR:-/opt/${REPO_NAME}}"
LOG_DIR="/var/log/${REPO_NAME}"

sudo mkdir -p "$INSTALL_DIR" "$LOG_DIR"
sudo chown -R $USER: "$INSTALL_DIR" "$LOG_DIR"

command -v git >/dev/null || { sudo apt-get update -y && sudo apt-get install -y git; }

clone_repo() {
  local url_https="$REPO_URL_DEFAULT"
  local url_ssh="git@${GIT_SSH_HOST:-github.com}:${REPO_OWNER}/${REPO_NAME}.git"

  case "${GIT_CLONE_METHOD:-https_public}" in
    https_public|"") git clone "$url_https" "$INSTALL_DIR" ;;
    https_pat)
      [ -n "${GIT_PAT:-}" ] || { echo "GIT_PAT saknas"; exit 1; }
      git clone "https://${GIT_PAT}@github.com/${REPO_OWNER}/${REPO_NAME}.git" "$INSTALL_DIR"
      ;;
    ssh)
      [ -n "${GIT_SSH_PRIVATE_KEY_B64:-}" ] || { echo "GIT_SSH_PRIVATE_KEY_B64 saknas"; exit 1; }
      sudo mkdir -p /root/.ssh
      echo "${GIT_SSH_PRIVATE_KEY_B64}" | base64 -d | sudo tee /root/.ssh/id_deploy >/dev/null
      sudo chmod 600 /root/.ssh/id_deploy
      GIT_SSH_COMMAND="ssh -i /root/.ssh/id_deploy -o StrictHostKeyChecking=accept-new" git clone "$url_ssh" "$INSTALL_DIR"
      [ "${GIT_SSH_PERSIST:-1}" = "1" ] || sudo shred -u /root/.ssh/id_deploy || true
      ;;
    *) echo "Okänd GIT_CLONE_METHOD"; exit 1;;
  esac
}

if [ ! -d "$INSTALL_DIR/.git" ]; then clone_repo
else git -C "$INSTALL_DIR" pull --ff-only || true; fi

cd "$INSTALL_DIR"

# firstboot-runner.service (dynamisk)
cat <<EOF | sudo tee /etc/systemd/system/firstboot-runner.service >/dev/null
[Unit]
Description=Kör ${REPO_NAME} första gången efter installation
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=${INSTALL_DIR}/firstboot-runner.sh
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF

# duckdns.service (dynamisk, pekar på rätt .env)
cat <<EOF | sudo tee /etc/systemd/system/duckdns.service >/dev/null
[Unit]
Description=Uppdatera DuckDNS
[Service]
Type=oneshot
EnvironmentFile=${INSTALL_DIR}/.env
ExecStart=/bin/bash -lc 'curl -fsS "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip="'
EOF

sudo cp systemd/duckdns.timer /etc/systemd/system/
sudo cp systemd/cloudflared.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now firstboot-runner.service
echo "firstboot-runner.service installerad."
