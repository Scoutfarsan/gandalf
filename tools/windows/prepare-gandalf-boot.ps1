# prepare-gandalf-boot.ps1
# Gandalf Zero-Touch v4.63-full-fat — SSH-ed25519 auto + (valfritt) GitHub-publicering via gh
# Körs på Windows innan SD-kortet sätts i Pi:n.

[CmdletBinding()]
param(
  # SSH-nyckel lokalt på Windows
  [string]$KeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
  [string]$KeyComment = "$($env:USERNAME)@$($env:COMPUTERNAME)-gandalf",

  # Mall-hantering
  [switch]$ForceOverwrite,          # återskapa env/secrets även om de finns

  # (A) Publicera PUBLIK konto-nyckel till ditt GitHub-konto (rekommenderad)
  [switch]$PublishToGitHub,         # lägg pubkey under Settings → SSH and GPG keys
  [string]$GitHubTitle = "gandalf-ed25519",

  # (B) Deploy key (per-repo, minst behörighet). Kräver gh & repo-access.
  [switch]$PublishDeployKey,        # lägg pubkey som deploy key på repo
  [string]$RepoOwner = "Scoutfarsan",
  [string]$RepoName  = "gandalf",
  [switch]$DeployRW                  # read-write (default off → read-only)
)

Write-Host "=== Gandalf Boot Helper v4.63 (full-fat) ===" -ForegroundColor Cyan

# --- Helpers ---
function Fail($msg){ Write-Error $msg; exit 1 }

function New-IfMissing {
  param([string]$Path,[string]$Content,[switch]$Secret,[switch]$Overwrite)
  if ($Overwrite -and (Test-Path $Path)) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
  if (-not (Test-Path $Path)) {
    $Content | Out-File -FilePath $Path -Encoding utf8 -Force
    if ($Secret) { Set-ItemProperty -Path $Path -Name Attributes -Value ([IO.FileAttributes]::Hidden) -ErrorAction SilentlyContinue }
    Write-Host ("Skapade: {0}" -f $Path) -ForegroundColor Yellow
  } else {
    Write-Host ("Fanns redan: {0} (orörd)" -f $Path) -ForegroundColor DarkGray
  }
}

function Ensure-Binary([string]$name,[string]$hint){
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Fail "$name saknas. $hint"
  }
}

function Ensure-Ed25519Key {
  param([string]$KeyPath,[string]$KeyComment)
  Ensure-Binary -name "ssh-keygen" -hint "Aktivera 'OpenSSH Client' i Windows Optional Features."
  $sshDir  = Split-Path -Parent $KeyPath
  $pubPath = "$KeyPath.pub"
  if (-not (Test-Path $pubPath)) {
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
    Write-Host "Ingen ssh-ed25519 hittad – genererar ny..." -ForegroundColor Yellow
    ssh-keygen -t ed25519 -a 100 -f $KeyPath -N "" -C $KeyComment | Out-Null
  }
  if (-not (Test-Path $pubPath)) { Fail "Misslyckades skapa/hitta $pubPath" }
  return $pubPath
}

function Ensure-GhAuth {
  Ensure-Binary -name "gh" -hint "Installera GitHub CLI via https://cli.github.com/"
  try { gh auth status *> $null } catch {
    Write-Host "GitHub CLI ej inloggad – startar device-login..." -ForegroundColor Cyan
    gh auth login
  }
}

function Publish-GitHubAccountKey {
  param([string]$PubKey,[string]$Title)
  Ensure-GhAuth
  Write-Host "Publicerar PUBLIK konto-nyckel till GitHub (titel: $Title)..." -ForegroundColor Cyan
  gh api -X POST /user/keys -f "title=$Title" -f "key=$PubKey" | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host "✔ Konto-nyckel upplagd." -ForegroundColor Green } else { Write-Warning "Kunde inte lägga upp konto-nyckeln." }
}

function Publish-GitHubDeployKey {
  param([string]$PubKey,[string]$Owner,[string]$Name,[switch]$RW)
  Ensure-GhAuth
  $readOnly = $true; if ($RW) { $readOnly = $false }
  Write-Host "Publicerar deploy key till $Owner/$Name (read_only=$($readOnly))..." -ForegroundColor Cyan
  # gh CLI saknar direkt flagga för deploy keys → använd API
  $payload = @{ title = "gandalf-deploy"; key = $PubKey; read_only = $readOnly } | ConvertTo-Json
  gh api -X POST "/repos/$Owner/$Name/keys" --input - --header "Content-Type: application/json" <<< $payload | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host "✔ Deploy key upplagd." -ForegroundColor Green } else { Write-Warning "Kunde inte lägga upp deploy key." }
}

# --- 1) Hitta BOOT (FAT32) ---
$bootDrive = Get-Volume | Where-Object { $_.FileSystem -eq 'FAT32' -and $_.DriveLetter } | Sort-Object DriveLetter | Select-Object -First 1
if (-not $bootDrive) { Fail "Ingen FAT32 BOOT-partition hittades. Sätt i SD-kortet och försök igen." }
$BOOT = ($bootDrive.DriveLetter + ":\")
Write-Host ("Använder BOOT-partition: {0}" -f $BOOT) -ForegroundColor Green

# --- 2) Skapa mappstruktur ---
$envPath     = Join-Path $BOOT "boot-env"
$secretsPath = Join-Path $BOOT "boot-secrets"
New-Item -ItemType Directory -Force -Path $envPath     | Out-Null
New-Item -ItemType Directory -Force -Path $secretsPath | Out-Null

# --- 3) ENV-mallar ---
$baseEnv = @'
# base.env — v4.63
PI_HOSTNAME="gandalf"
SITE_LABEL="Hem"

LAN_BASE="10.20.30"
LAN_CIDR="${LAN_BASE}.0/24"
LAN_GW="${LAN_BASE}.1"
PI_IP="${LAN_BASE}.2"

VPN_BASE="10.20.35"
WG_NETWORK="${VPN_BASE}.0/24"
WG_SERVER_IP="${VPN_BASE}.1"

ADMIN_VPN_BASE="10.20.31"
GUEST_VPN_BASE="10.20.32"
REMOTE_SITE_BASE="10.20.40"

DUCKDNS_DOMAIN=""
DUCKDNS_ENABLE=0

DNSFILTER_ENABLE=1
LOCAL_DNS_ENABLE=0
'@

$dhcpEnv = @'
# dhcp.env — v4.63
DHCP_INFRA_RANGE="11-19"
DHCP_LARM_RANGE="31-39"
DHCP_SHARED_RANGE="41-49"
DHCP_ALEX_RANGE="51-59"
DHCP_ELIN_RANGE="61-69"
DHCP_JON_RANGE="71-79"
DHCP_MATH_RANGE="81-89"
DHCP_PAR_RANGE="91-99"
DHCP_GUEST_BASE="10.20.32"
DHCP_GUEST_RANGE="151-199"
DHCP_ACTIVATE=0
'@

$vpnEnv = @'
# vpn.env — v4.63
TS_ADVERTISE_ROUTES="${LAN_BASE}.0/24"
TS_ACCEPT_DNS=true
TS_ADVERTISE_EXIT=true
WG_INTERFACE="wg0"
WG_PORT="51820"
'@

$loggingEnv = @'
# logging.env — v4.63
GRAFANA_URL="https://example.grafana.net"
LOKI_LOCAL_URL="http://127.0.0.1:3100"
PROMTAIL_POSITIONS="/var/lib/promtail/positions.yaml"
'@

$wifiEnv = @'
# wifi.env — v4.63 (Wi-Fi failover alltid aktiv)
WIFI_COUNTRY=SE
ETH_METRIC=100
WIFI_METRIC=200
WIFI_SSID1="SSID-primar"
WIFI_SSID2="SSID-sekundar"
WIFI_SSID3="SSID-tertiar"
'@

# --- 4) SECRET-mallar ---
$coreSec = @'
# core.env — v4.63 (SECRETS)
TS_AUTHKEY=""
HC_RUNTIME_UUID=""
DUCKDNS_TOKEN=""
GRAFANA_API_KEY=""
PIHOLE_WEBPASSWORD=""
'@

$ntfySec = @'
# ntfy.env — v4.63 (SECRETS)
NTFY_RUNTIME_URL=""
NTFY_SETUP_URL=""
'@

$wifiSec = @'
# wifi.env — v4.63 (SECRETS)
WIFI_PSK1=""
WIFI_PSK2=""
WIFI_PSK3=""
'@

# --- 5) Skriv mallar (idempotent; -ForceOverwrite nollställer) ---
$ow = [bool]$ForceOverwrite
New-IfMissing (Join-Path $envPath "base.env")    $baseEnv     -Overwrite:$ow
New-IfMissing (Join-Path $envPath "dhcp.env")    $dhcpEnv     -Overwrite:$ow
New-IfMissing (Join-Path $envPath "vpn.env")     $vpnEnv      -Overwrite:$ow
New-IfMissing (Join-Path $envPath "logging.env") $loggingEnv  -Overwrite:$ow
New-IfMissing (Join-Path $envPath "wifi.env")    $wifiEnv     -Overwrite:$ow
New-IfMissing (Join-Path $envPath "ssh_authorized_keys") "# Lägg publika nycklar här (en per rad)" -Overwrite:$ow

New-IfMissing (Join-Path $secretsPath "core.env") $coreSec  -Secret -Overwrite:$ow
New-IfMissing (Join-Path $secretsPath "ntfy.env") $ntfySec  -Secret -Overwrite:$ow
New-IfMissing (Join-Path $secretsPath "wifi.env") $wifiSec  -Secret -Overwrite:$ow

# --- 6) SSH-ed25519: generera/återanvänd & lägg i authorized_keys ---
$pubPath = Ensure-Ed25519Key -KeyPath $KeyPath -KeyComment $KeyComment
$pubKey  = (Get-Content $pubPath -Raw).Trim()
$authKeys = Join-Path $envPath "ssh_authorized_keys"
if (-not (Test-Path $authKeys)) { "# ssh_authorized_keys" | Out-File -FilePath $authKeys -Encoding utf8 }
$exists = Select-String -Path $authKeys -Pattern ([regex]::Escape($pubKey)) -Quiet -ErrorAction SilentlyContinue
if (-not $exists) { Add-Content -Path $authKeys -Value $pubKey; Write-Host "La till publik nyckel i ssh_authorized_keys." -ForegroundColor Green } else { Write-Host "Publik nyckel fanns redan i ssh_authorized_keys." -ForegroundColor DarkGray }

try {
  $fp = (ssh-keygen -lf $pubPath) -join "`n"
  Write-Host "`nFingerprint:" -ForegroundColor Cyan
  Write-Host $fp
} catch {}

# --- 7) Valfri GitHub-publicering via gh ---
if ($PublishToGitHub -and $PublishDeployKey) {
  Write-Warning "Både -PublishToGitHub och -PublishDeployKey angivna – kör konto-nyckel i första hand."
}
if ($PublishToGitHub) {
  Publish-GitHubAccountKey -PubKey $pubKey -Title $GitHubTitle
}
elseif ($PublishDeployKey) {
  Publish-GitHubDeployKey -PubKey $pubKey -Owner $RepoOwner -Name $RepoName -RW:$DeployRW
}

# --- 8) Summering & öppna filer i Notepad ---
Write-Host "`nFiler på BOOT:" -ForegroundColor Cyan
Get-ChildItem -Recurse -File $envPath,$secretsPath | ForEach-Object { $_.FullName.Replace($BOOT,'BOOT:\') }

Write-Host "`nÖppnar env/secrets i Notepad..." -ForegroundColor Cyan
$allFiles = (Get-ChildItem $envPath -File) + (Get-ChildItem $secretsPath -File)
foreach ($f in $allFiles) { Start-Process notepad.exe $f.FullName }

Write-Host "`n=== Klart! Mata ut SD-kortet säkert och boota din Pi. ===" -ForegroundColor Green
