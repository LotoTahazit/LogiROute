# Одноразовая настройка gcloud для LogiRoute (Windows)
#
# Если PowerShell блокирует .ps1, используйте:
#   scripts\gcloud_setup.cmd
# или:
#   powershell -ExecutionPolicy Bypass -File scripts\gcloud_setup.ps1

$ErrorActionPreference = "Stop"
$PROJECT = "logiroute-app"

function Find-Gcloud {
  $candidates = @(
    "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "$env:ProgramFiles\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
  )
  foreach ($p in $candidates) {
    if (Test-Path $p) { return $p }
  }
  throw "gcloud не найден. Установите: winget install Google.CloudSDK"
}

$gcloud = Find-Gcloud
$binDir = Split-Path $gcloud -Parent
if ($env:Path -notlike "*$binDir*") {
  $env:Path = "$binDir;$env:Path"
}

Write-Host "gcloud:" (& $gcloud --version | Select-Object -First 1)

$accounts = & $gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $accounts) {
  Write-Host "`n🔐 Вход в Google Cloud (откроется браузер)..."
  & $gcloud auth login --update-adc
}

& $gcloud config set project $PROJECT | Out-Null
Write-Host "✅ Проект: $PROJECT"

Write-Host "`n📦 Firestore Backup (через firebase login + node)..."
Push-Location (Split-Path $PSScriptRoot -Parent)
node scripts/enable_gcp_firestore_backup.js
Pop-Location

Write-Host "`n💡 Проверка через gcloud (после login):"
Write-Host "   scripts\list_firestore_backups.cmd"
