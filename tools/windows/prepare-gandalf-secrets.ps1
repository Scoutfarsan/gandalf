param([string]\='E')
\ = "\:\boot-secrets"
New-Item -ItemType Directory -Force -Path \ | Out-Null
'core.env','ntfy.env','tailscale.env','duckdns.env','grafana.env','healthchecks.env' | %{
  if(-not (Test-Path "\\")){ New-Item -ItemType File "\\" | Out-Null }
}
Write-Host "Editera \ClientHealth hp inetpub Intel PerfLogs Program Files Program Files (x86) Radioddity SWSetup system.sav temp Users VGRIT_Temp Windows ConfigMgrAdminUISetup.log ConfigMgrAdminUISetupVerbose.log DumpStack.log i \ innan boot."