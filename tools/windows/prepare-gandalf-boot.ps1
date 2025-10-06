# tools/windows/prepare-gandalf-boot.ps1 — v6.43 (no-age-on-win)
[CmdletBinding()]
param(
  [string]$KeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
  [string]$KeyComment = "$($env:USERNAME)@$($env:COMPUTERNAME)-gandalf",
  [string]$AgeKeyPath = "$env:USERPROFILE\.config\age\age.key",
  [switch]$ForceOverwrite
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-IfMissing {
  param([string]$Path,[string]$Content,[switch]$Secret,[switch]$Overwrite)
  if ($Overwrite -and (Test-Path $Path)) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
  if (-not (Test-Path $Path)) {
    $Content | Out-File -FilePath $Path -Encoding utf8 -Force
    if ($Secret) { try { Set-ItemProperty -Path $Path -Name Attributes -Value ([IO.FileAttributes]::Hidden) } catch {} }
  }
}

function Ensure-Ed25519Key {
  param([string]$KeyPath,[string]$KeyComment)
  $ssh = Get-Command ssh-keygen -ErrorAction SilentlyContinue
  if (-not $ssh) { throw "ssh-keygen saknas. Aktivera 'OpenSSH Client' i Windows (Optional Features)." }
  $sshDir  = Split-Path -Parent $KeyPath
  $pubPath = "$KeyPath.pub"
  if (-not (Test-Path $pubPath)) {
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
    ssh-keygen -t ed25519 -a 100 -f $KeyPath -N "" -C $KeyComment | Out-Null
  }
  if (-not (Test-Path $pubPath)) { throw "Misslyckades skapa $pubPath" }
  return $pubPath
}

$bootDrive = Get-Volume | Where-Object { $_.FileSystem -eq 'FAT32' -and $_.DriveLetter } | Sort-Object DriveLetter | Select-Object -First 1
if (-not $bootDrive) { throw "Ingen FAT32 BOOT-partition hittades." }
$BOOT = ($bootDrive.DriveLetter + ":\")
$envPath     = Join-Path $BOOT "boot-env"
$secretsPath = Join-Path $BOOT "boot-secrets"
New-Item -ItemType Directory -Force -Path $envPath,$secretsPath | Out-Null

$baseEnv = @'
# base.env — v6.43
PI_HOSTNAME="gandalf"
SITE_LABEL="Hem"
TZ="Europe/Stockholm"
LOCALE="sv_SE.UTF-8"
LOG_LEVEL="info"
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
RESOLVER_MODE="recursive"
DUCKDNS_DOMAIN="scoutfarsan"
REPO_OWNER="Scoutfarsan"
REPO_NAME="gandalf"
GIT_CLONE_METHOD="https_public"
'@

$dhcpEnv = @'
# dhcp.env — v6.43
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
# vpn.env — v6.43
WG_INTERFACE="wg0"
WG_PORT="51820"
TS_ADVERTISE_ROUTES="${LAN_BASE}.0/24"
TS_ACCEPT_DNS=true
TS_ADVERTISE_EXIT=true
WG_REQUEST_BIND="0.0.0.0"
WG_REQUEST_PORT="8088"
WG_PORTAL_BASE_URL="http://pihole.lan:8088"
WG_DB_PATH="/var/lib/wg-portal/db.sqlite"
WG_REQUEST_BASE_URL="http://pihole.lan:8088/wg"
'@

$loggingEnv = @'
# logging.env — v6.43
LOKI_LOCAL_URL="http://127.0.0.1:3100"
PROMTAIL_POSITIONS="/var/lib/promtail/positions.yaml"
GRAFANA_URL="https://scoutfarsan.grafana.net"
GRAFANA_USER=""
'@

$wifiEnv = @'
# wifi.env — v6.43
WIFI_COUNTRY="SE"
ETH_METRIC=100
WIFI_METRIC=200
WIFI_SSID1="SSID-primar"
WIFI_SSID2="SSID-sekundar"
WIFI_SSID3="SSID-tertiar"
'@

$coreSec = @'
# core.env — v6.43 (ROTATE ASAP)
TS_AUTHKEY="tskey-auth-kLVRgyyeiF11CNTRL-EfFzYkSKFAZGis8ccuT7AZQq9a2pD5b2"
PIHOLE_WEBPASSWORD="Hemma2004"
HC_SETUP_UUID="46beb3ef-2c1e-4a5d-8e0a-08d69400aff1"
HC_RUNTIME_UUID="46beb3ef-2c1e-4a5d-8e0a-08d69400aff1"
DUCKDNS_TOKEN="0972f917-cf51-4578-9c0b-0ab4df6b91f5"
GRAFANA_API_KEY="eyJUb2tlbiI6ImdsY19..."
WG_REQUEST_TOKEN="bytmig-XYZ"
WG_PORTAL_ADMIN_KEY="byt-denna-adminnyckel"
'@

$ntfySec = @'
# ntfy.env — v6.43
NTFY_SETUP_URL="https://ntfy.sh/c2FuMXN5MBTX1BPX"
NTFY_RUNTIME_URL="https://ntfy.sh/pcLgFKQhYsKeAvZI"
'@

$wifiSec = @'
# wifi.env — v6.43
WIFI_PSK1=""
WIFI_PSK2=""
WIFI_PSK3=""
'@

$ow=[bool]$ForceOverwrite
$files = @{
  (Join-Path $envPath "base.env")    = $baseEnv
  (Join-Path $envPath "dhcp.env")    = $dhcpEnv
  (Join-Path $envPath "vpn.env")     = $vpnEnv
  (Join-Path $envPath "logging.env") = $loggingEnv
  (Join-Path $envPath "wifi.env")    = $wifiEnv
  (Join-Path $secretsPath "core.env")= $coreSec
  (Join-Path $secretsPath "ntfy.env")= $ntfySec
  (Join-Path $secretsPath "wifi.env")= $wifiSec
}
foreach($k in $files.Keys){ New-IfMissing $k $files[$k] -Secret:($k -like "*boot-secrets*") -Overwrite:$ow }

# SSH authorized_keys
$pubPath = Ensure-Ed25519Key -KeyPath $KeyPath -KeyComment $KeyComment
$pubKey  = Get-Content $pubPath -Raw
$authKeys = Join-Path $envPath "ssh_authorized_keys"
if (-not (Test-Path $authKeys)) { "" | Out-File -FilePath $authKeys -Encoding utf8 -Force }
if (-not (Select-String -Path $authKeys -Pattern ([regex]::Escape($pubKey.Trim())) -Quiet)) {
  Add-Content -Path $authKeys -Value $pubKey
}

# (Valfritt) Kopiera age.key om den råkar finnas — annars sköter Pi:n allt
if (Test-Path $AgeKeyPath) {
  Copy-Item -LiteralPath $AgeKeyPath -Destination (Join-Path $secretsPath "age.key") -Force
}

Write-Host "✅ BOOT prepp klar."
