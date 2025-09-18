# prepare-gandalf-boot.ps1
# Gandalf Zero-Touch v4.63-full-fat
# Skapar boot-env/ och boot-secrets/ på BOOT-partitionen och skriver mallar.
# Körs på Windows innan SD-kortet flyttas till din Pi.

[CmdletBinding()]
param()

Write-Host "=== Gandalf Boot Helper v4.63-full-fat ===" -ForegroundColor Cyan

# --- Hitta BOOT (FAT32) ---
$bootDrive = Get-Volume | Where-Object {
  $_.FileSystem -eq 'FAT32' -and $_.DriveLetter
} | Sort-Object DriveLetter | Select-Object -First 1

if (-not $bootDrive) {
  Write-Error "Kunde inte hitta någon FAT32-partition (BOOT). Sätt i SD-kortet och försök igen."
  exit 1
}

$BOOT = ($bootDrive.DriveLetter + ":\")
Write-Host ("Använder BOOT-partition: {0}" -f $BOOT) -ForegroundColor Green

# --- Skapa målmappstruktur ---
$envPath     = Join-Path $BOOT "boot-env"
$secretsPath = Join-Path $BOOT "boot-secrets"

New-Item -ItemType Directory -Force -Path $envPath     | Out-Null
New-Item -ItemType Directory -Force -Path $secretsPath | Out-Null

# --- Små hjälpare ---
function New-IfMissing {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Content,
    [switch]$Secret
  )
  if (-not (Test-Path -LiteralPath $Path)) {
    $Content | Out-File -FilePath $Path -Encoding utf8 -Force
    if ($Secret) {
      # markera (metadata) – på BOOT kan vi ej sätta POSIX-rättigheter, men vi flaggar för tydlighet
      Set-ItemProperty -Path $Path -Name Attributes -Value ([IO.FileAttributes]::Hidden) -ErrorAction SilentlyContinue
    }
    Write-Host ("Skapade: {0}" -f $Path) -ForegroundColor Yellow
  } else {
    Write-Host ("Fanns redan: {0} (orörd)" -f $Path) -ForegroundColor DarkGray
  }
}

# --- ENV-mallar (ofarliga konfigar) ---
$baseEnv = @'
# base.env — v4.63
PI_HOSTNAME="gandalf"
SITE_LABEL="Hem"

# Basnät (a.b.c)
LAN_BASE="10.20.30"
LAN_CIDR="${LAN_BASE}.0/24"
LAN_GW="${LAN_BASE}.1"
PI_IP="${LAN_BASE}.2"

# VPN-nät
VPN_BASE="10.20.35"
WG_NETWORK="${VPN_BASE}.0/24"
WG_SERVER_IP="${VPN_BASE}.1"

# Framtida segment
ADMIN_VPN_BASE="10.20.31"
GUEST_VPN_BASE="10.20.32"
REMOTE_SITE_BASE="10.20.40"

# DNS/externa tjänster
DUCKDNS_DOMAIN=""
DUCKDNS_ENABLE=0

# Filtrering
DNSFILTER_ENABLE=1
LOCAL_DNS_ENABLE=0
'@

$dhcpEnv = @'
# dhcp.env — v4.63
# Alla scopes skrivs dynamiskt av m301-dhcp
DHCP_INFRA_RANGE="11-19"
DHCP_LARM_RANGE="31-39"
DHCP_SHARED_RANGE="41-49"
DHCP_ALEX_RANGE="51-59"
DHCP_ELIN_RANGE="61-69"
DHCP_JON_RANGE="71-79"
DHCP_MATH_RANGE="81-89"
DHCP_PAR_RANGE="91-99"

# Gästnät (separat bas)
DHCP_GUEST_BASE="10.20.32"
DHCP_GUEST_RANGE="151-199"

# Aktivera endast när du är redo
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
# Tre SSID i fallande prio (30 > 20 > 10)
WIFI_SSID1="SSID-primar"
WIFI_SSID2="SSID-sekundar"
WIFI_SSID3="SSID-tertiar"
'@

# --- SECRET-mallar (placera aldrig i repo) ---
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

# --- Skriv filer (skapa endast om saknas) ---
New-IfMissing -Path (Join-Path $envPath     "base.env")             -Content $baseEnv
New-IfMissing -Path (Join-Path $envPath     "dhcp.env")             -Content $dhcpEnv
New-IfMissing -Path (Join-Path $envPath     "vpn.env")              -Content $vpnEnv
New-IfMissing -Path (Join-Path $envPath     "logging.env")          -Content $loggingEnv
New-IfMissing -Path (Join-Path $envPath     "wifi.env")             -Content $wifiEnv
New-IfMissing -Path (Join-Path $envPath     "ssh_authorized_keys")  -Content "# Klistra in din publika nyckel här (t.ex. ssh-ed25519 AAAA... kommentar)"

New-IfMissing -Path (Join-Path $secretsPath "core.env")             -Content $coreSec -Secret
New-IfMissing -Path (Join-Path $secretsPath "ntfy.env")             -Content $ntfySec -Secret
New-IfMissing -Path (Join-Path $secretsPath "wifi.env")             -Content $wifiSec -Secret

# --- Summering / sanity check ---
Write-Host "`nFöljande mappar/filer finns nu på BOOT:" -ForegroundColor Cyan
Get-ChildItem -Recurse -File $envPath,$secretsPath | ForEach-Object {
  $_.FullName.Replace($BOOT,'BOOT:\')
}

# --- Öppna för editering ---
Write-Host "`nÖppnar env/secrets i Notepad..." -ForegroundColor Cyan
$allFiles = (Get-ChildItem $envPath -File) + (Get-ChildItem $secretsPath -File)
foreach ($f in $allFiles) { Start-Process notepad.exe $f.FullName }

Write-Host "`n=== Klart! Mata ut kortet säkert och boota din Pi. ===" -ForegroundColor Green
