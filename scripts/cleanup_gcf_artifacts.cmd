@echo off
REM Очистка артефактов Cloud Functions (Artifact Registry + пустые пакеты)
setlocal
set GC=D:\Projects_A\LogiRoute3\scripts\gcloud.cmd
set PROJECT=logiroute-app
set REPO=gcf-artifacts
set LOC=us-central1

echo === LogiRoute: cleanup GCF artifacts ===
echo Project: %PROJECT%
echo.

echo [1/3] Размер репозиториев...
call "%GC%" artifacts repositories list --project=%PROJECT% --format="table(name,location,sizeBytes)"
echo.

echo [2/3] Удаление пустых пакетов cache (без версий)...
for %%P in (
  cleanup_driver_history/cache
  cleanup_pod_photos/cache
  on_point_assigned/cache
  scheduled_integrity_check/cache
  send_company_email/cache
) do (
  call "%GC%" artifacts versions list --package=%%P --repository=%REPO% --location=%LOC% --project=%PROJECT% --format="value(VERSION)" 2>nul | findstr /R "." >nul
  if errorlevel 1 (
    echo   delete empty: %%P
    call "%GC%" artifacts packages delete "%%P" --repository=%REPO% --location=%LOC% --project=%PROJECT% --quiet 2>nul
  )
)
echo.

echo [3/3] Политика автоочистки (untagged ^>7d, keep 3 tagged)...
call "%GC%" artifacts repositories set-cleanup-policies %REPO% --location=%LOC% --project=%PROJECT% --policy=%~dp0cleanup_gcf_artifacts.json --quiet
echo.

echo === Готово ===
call "%GC%" artifacts repositories list --project=%PROJECT% --filter="name:gcf-artifacts" --format="table(name,location,sizeBytes)"
pause
