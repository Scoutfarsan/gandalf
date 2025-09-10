#!/usr/bin/env bash
set -euo pipefail
if [ -f /boot/firmware/secrets.env ]; then set -a; . /boot/firmware/secrets.env; set +a; fi
if [ -f /boot/firmware/.env ]; then set -a; . /boot/firmware/.env; set +a; fi

INSTALL_DIR="${INSTALL_DIR:-/opt/${REPO_NAME:-gandalf}}"
REPO_OWNER="${REPO_OWNER:-Scoutfarsan}"; REPO_NAME="${REPO_NAME:-gandalf}"
GIT_CLONE_METHOD="${GIT_CLONE_METHOD:-https_public}"
REPO_URL_HTTPS="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
REPO_URL_SSH="git@github.com:${REPO_OWNER}/${REPO_NAME}.git"

echo "[refresh] ${REPO_OWNER}/${REPO_NAME} -> ${INSTALL_DIR}"
sudo systemctl disable --now firstboot-runner.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/firstboot-runner.service
sudo systemctl daemon-reload

sudo rm -rf "${INSTALL_DIR}" "/var/log/${REPO_NAME}"
sudo mkdir -p "/var/log/${REPO_NAME}"
sudo apt-get update -y && sudo apt-get install -y git ca-certificates curl

case "$GIT_CLONE_METHOD" in
  https_public|"") sudo git clone "$REPO_URL_HTTPS" "$INSTALL_DIR" ;;
  https_pat) [ -n "${GIT_PAT:-}" ] || { echo "GIT_PAT saknas"; exit 1; }
             sudo git clone "https://${GIT_PAT}@github.com/${REPO_OWNER}/${REPO_NAME}.git" "$INSTALL_DIR" ;;
  ssh) [ -n "${GIT_SSH_PRIVATE_KEY_B64:-}" ] || { echo "GIT_SSH_PRIVATE_KEY_B64 saknas"; exit 1; }
      sudo mkdir -p /root/.ssh
      echo "${GIT_SSH_PRIVATE_KEY_B64}" | base64 -d | sudo tee /root/.ssh/id_deploy >/dev/null
      sudo chmod 600 /root/.ssh/id_deploy
      sudo GIT_SSH_COMMAND='ssh -i /root/.ssh/id_deploy -o StrictHostKeyChecking=accept-new' git clone "$REPO_URL_SSH" "$INSTALL_DIR"
      [ "${GIT_SSH_PERSIST:-1}" = "1" ] || sudo shred -u /root/.ssh/id_deploy || true ;;
  *) echo "Okänd GIT_CLONE_METHOD"; exit 1 ;;
esac

[ -f /boot/firmware/.env ] && sudo cp /boot/firmware/.env "$INSTALL_DIR/.env" || true
[ -f /boot/firmware/secrets.env ] && sudo cp /boot/firmware/secrets.env "$INSTALL_DIR/secrets.env" || true

sudo find "$INSTALL_DIR" -type f -name "*.sh" -exec sed -i 's/\r$//' {} +
sudo find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} +

bash "${INSTALL_DIR}/install.sh"
