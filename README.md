# ${REPO_NAME} – Home Infra (prod)
Repo med tre mappar: `/modules`, `/scripts`, `/tools`. All konfig rullas ut via `./scripts/install.sh`.
- Dynamiskt: alla paths använder `${REPO_NAME}` från `/etc/${REPO_NAME}/.env`.
- Idempotent: säkert att köra flera gånger.
- Staged DHCP: `DHCP_ACTIVATE=0` tills du slår på.

## Quickstart
```bash
cd /opt/${REPO_NAME}
sudo mkdir -p /etc/${REPO_NAME}
sudo cp scripts/env/.env.sample /etc/${REPO_NAME}/.env
sudo cp scripts/env/secrets.env.sample /etc/${REPO_NAME}/secrets.env
sudo chmod 600 /etc/${REPO_NAME}/secrets.env
sudo ./scripts/install.sh
```
