@echo off
chcp 65001 >nul
setlocal EnableExtensions
cd /d "%~dp0.."

set "GCLOUD=%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
if not exist "%GCLOUD%" set "GCLOUD=%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
if not exist "%GCLOUD%" (
  echo gcloud ne naiden. Ustanovite: winget install Google.CloudSDK
  exit /b 1
)

set "PATH=%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin;%PATH%"
set "PROJECT=logiroute-app"

echo === gcloud ===
call "%GCLOUD%" --version
echo.

echo === proverka vhoda ===
call "%GCLOUD%" auth list --filter=status:ACTIVE --format="value(account)" > "%TEMP%\gcloud_acct.txt" 2>nul
for /f "usebackq delims=" %%A in ("%TEMP%\gcloud_acct.txt") do set "ACCT=%%A"
if not defined ACCT goto DO_LOGIN
echo Vhod: %ACCT%
goto AFTER_LOGIN

:DO_LOGIN
echo Vhod v Google Cloud - otkroetsya brauzer...
call "%GCLOUD%" auth login --update-adc
if errorlevel 1 (
  echo Oshibka vhoda.
  exit /b 1
)

:AFTER_LOGIN
call "%GCLOUD%" config set project %PROJECT%
call "%GCLOUD%" auth application-default set-quota-project %PROJECT% >nul 2>nul
echo Proekt: %PROJECT%
echo.

echo === Firestore Backup ===
node scripts\enable_gcp_firestore_backup.js
if errorlevel 1 exit /b 1

echo.
echo Gotovo. V PowerShell:
echo   scripts\list_firestore_backups.cmd
echo ili:
echo   scripts\gcloud.cmd firestore backups schedules list "--database=(default)"
echo.
echo Ne zabudte kavichki vokrug (default) v PowerShell!
