# Pi-hole Hemma – Automatisk installation

Detta repo innehåller en komplett lösning för att sätta upp Pi-hole + Unbound + WireGuard m.m. på en Raspberry Pi.

## 🔧 Repo-inställningar (.env)

Du **måste alltid** sätta:

```bash
REPO_OWNER="dittkonto"
REPO_NAME="pihole"
```

### Välj kloningsmetod:

#### 1. Offentligt repo (ingen auth)
```bash
GIT_CLONE_METHOD="https_public"
```
Klonar från:
```
https://github.com/${REPO_OWNER}/${REPO_NAME}.git
```

#### 2. Privat repo via Personal Access Token (PAT)
```bash
GIT_CLONE_METHOD="https_pat"
GIT_PAT="ghp_xxxDIN_TOKENxxx"
```
Klonar från:
```
https://${GIT_PAT}@github.com/${REPO_OWNER}/${REPO_NAME}.git
```
Tips: använd en *fine-grained PAT* med **read-only** access till just detta repo.

#### 3. Privat repo via SSH deploy key
```bash
GIT_CLONE_METHOD="ssh"
GIT_SSH_PRIVATE_KEY_B64="LS0tLS1CRUdJTiBQUklWQVRF...tLS0tLUVORCBQUklWQVRFIEtFWS0tLS0t"
```

Valfria inställningar:
```bash
GIT_SSH_HOST="github.com"   # standard är github.com
GIT_SSH_PERSIST="1"         # 1 = behåll nyckeln för framtida git pull, 0 = ta bort direkt efter klon
```

Klonar från:
```
git@${GIT_SSH_HOST}:${REPO_OWNER}/${REPO_NAME}.git
```

### 📂 Installationsmapp
Byggs automatiskt:
```
INSTALL_DIR="/opt/${REPO_NAME}"
```
Exempel: `pihole` installeras i `/opt/pihole`.

---

## 🔑 SSH nyckel – base64
Om du valt `ssh` behöver du base64-koda din privata deploy-nyckel:

```bash
cat id_ed25519 | base64 -w0
```

Kopiera resultatet till `.env` som `GIT_SSH_PRIVATE_KEY_B64`.

---

## 📡 Notifieringar (ntfy)
Fyll i notifieringsadresser i `.env`:
```bash
NTFY_SETUP_URL="https://ntfy.sh/xxxx"
NTFY_RUNTIME_URL="https://ntfy.sh/yyyy"
NTFY_URL="https://subdomän.domännamn.se/zzzz" # BACKUP
```

---

## 🚀 Installation
1. Skapa repon på GitHub (`${REPO_OWNER}/${REPO_NAME}`).
2. Lägg upp innehållet från `pihole/` i repot.
3. På SD-kortets **boot**-partition:
   - Kopiera in filerna från `boot_pack/`.
   - Kopiera `.env.sample` → `.env` och fyll i ovanstående värden.
4. Stoppa in kortet i din Raspberry Pi och starta.
5. Följ notifieringar i ntfy för progress.

---

## 🛡️ Tips & säkerhet
- Använd **SSH deploy key** hellre än PAT för privat repo.
- Om du använder PAT, gör den *fine-grained* och ge bara **read access**.
- Alla hemligheter (tokens, nycklar) ligger i `.env` – lägg inte upp den publikt!
