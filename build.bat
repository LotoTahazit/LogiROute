@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "ENV_FILE=.env.local"
set "WEB_FLAGS=--dart-define-from-file=%ENV_FILE% --release --pwa-strategy=none"
set "APK_FLAGS=--release --dart-define-from-file=%ENV_FILE%"

if exist ".tools\node\firebase.cmd" (
  set "FIREBASE=.tools\node\firebase.cmd"
) else (
  set "FIREBASE=firebase"
)

if "%~1"=="" goto menu
if /i "%~1"=="web" goto build_web
if /i "%~1"=="deploy" goto deploy_web
if /i "%~1"=="web-deploy" goto deploy_web
if /i "%~1"=="apk" goto build_apk
if /i "%~1"=="all" goto build_all
if /i "%~1"=="full" goto build_full
if /i "%~1"=="patch" goto patch_only
if /i "%~1"=="clean" goto do_clean
echo Usage: build.bat [web^|deploy^|apk^|all^|full^|patch^|clean]
exit /b 1

:menu
echo LogiRoute build
echo   1 web    - build web
echo   2 deploy - build web + patch + firebase hosting
echo   3 apk    - build release APK
echo   4 all    - clean + web + apk
echo   5 full   - clean + web + apk + firebase deploy
echo   6 patch  - patch web bootstrap only
echo   7 clean
echo   8 exit
set /p choice=Choice:
if "%choice%"=="1" goto build_web
if "%choice%"=="2" goto deploy_web
if "%choice%"=="3" goto build_apk
if "%choice%"=="4" goto build_all
if "%choice%"=="5" goto build_full
if "%choice%"=="6" goto patch_only
if "%choice%"=="7" goto do_clean
if "%choice%"=="8" exit /b 0
goto menu

:build_web
flutter build web %WEB_FLAGS%
if errorlevel 1 exit /b 1
powershell -ExecutionPolicy Bypass -File "%~dp0patch_web_bootstrap.ps1"
exit /b %errorlevel%

:deploy_web
echo [LogiRoute] build web + patch + firebase hosting...
flutter build web %WEB_FLAGS%
if errorlevel 1 exit /b 1
powershell -ExecutionPolicy Bypass -File "%~dp0patch_web_bootstrap.ps1"
if errorlevel 1 exit /b 1
call "%FIREBASE%" deploy --only hosting
exit /b %errorlevel%

:build_apk
flutter build apk %APK_FLAGS%
exit /b %errorlevel%

:build_all
call "%~f0" clean
if errorlevel 1 exit /b 1
call "%~f0" web
if errorlevel 1 exit /b 1
call "%~f0" apk
exit /b %errorlevel%

:build_full
call "%~f0" all
if errorlevel 1 exit /b 1
call "%FIREBASE%" deploy
exit /b %errorlevel%

:patch_only
powershell -ExecutionPolicy Bypass -File "%~dp0patch_web_bootstrap.ps1"
exit /b %errorlevel%

:do_clean
flutter clean
flutter pub get
exit /b 0
