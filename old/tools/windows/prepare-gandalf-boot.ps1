param([string]\='E')
\ = "\:\boot-env"
New-Item -ItemType Directory -Force -Path \ | Out-Null
Set-Content -Path "\\base.env" -NoNewline -Encoding utf8 -Value @'
REPO_OWNER="Scoutfarsan"
REPO_NAME="gandalf"
GIT_CLONE_BRANCH="main"
'@
Write-Host "Wrote \\base.env"