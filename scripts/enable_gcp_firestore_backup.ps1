# Firestore Backup через gcloud (после scripts/gcloud_setup.cmd)
$ErrorActionPreference = "Stop"
$PROJECT = "logiroute-app"

$gcloud = @(
  "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
  "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $gcloud) { throw "gcloud ne naiden. Zapustite: scripts\gcloud_setup.cmd" }

& $gcloud config set project $PROJECT | Out-Null

$existing = & $gcloud firestore backups schedules list --database="(default)" --format="value(name)" 2>$null
if ($existing) {
  Write-Host "Raspisanie uzhe est:"
  & $gcloud firestore backups schedules list --database="(default)"
  exit 0
}

Write-Host "Sozdaem daily backup, retention 14d..."
& $gcloud firestore backups schedules create `
  --database="(default)" `
  --recurrence=daily `
  --retention=14d

& $gcloud firestore backups schedules list --database="(default)"
