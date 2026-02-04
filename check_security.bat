@echo off
echo ========================================
echo   Проверка безопасности LogiRoute
echo ========================================
echo.

REM Проверка 1: .env не в Git
echo [1/4] Проверка .env в Git...
git ls-files | findstr /C:".env" >nul 2>&1
if %errorlevel% equ 0 (
    echo [FAIL] .env файл найден в Git! УДАЛИТЕ ЕГО НЕМЕДЛЕННО!
    echo        Выполните: git rm --cached .env
) else (
    echo [OK] .env не в Git
)
echo.

REM Проверка 2: .env в .gitignore
echo [2/4] Проверка .gitignore...
findstr /C:".env" .gitignore >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] .env в .gitignore
) else (
    echo [FAIL] .env НЕ в .gitignore! Добавьте его!
    echo        Выполните: echo .env >> .gitignore
)
echo.

REM Проверка 3: .env существует локально
echo [3/4] Проверка локального .env...
if exist .env (
    echo [OK] .env файл существует локально
    
    REM Проверка на placeholder ключи
    findstr /C:"your_web_api_key_here" .env >nul 2>&1
    if %errorlevel% equ 0 (
        echo [WARN] .env содержит placeholder ключи!
        echo        Замените их на реальные ключи из Google Cloud Console
    ) else (
        echo [OK] .env содержит реальные ключи
    )
) else (
    echo [FAIL] .env файл НЕ существует!
    echo        Скопируйте: copy .env.example .env
    echo        И добавьте реальные ключи
)
echo.

REM Проверка 4: firebase_options.dart
echo [4/4] Проверка firebase_options.dart...
if exist lib\firebase_options.dart (
    echo [INFO] firebase_options.dart существует
    echo        Firebase ключи для клиентских приложений обычно не секретны
    echo        НО убедитесь что настроены Firebase Security Rules!
) else (
    echo [WARN] firebase_options.dart не найден
)
echo.

echo ========================================
echo   Проверка завершена
echo ========================================
echo.
echo Рекомендации:
echo 1. Убедитесь что .env НЕ в Git
echo 2. Настройте ограничения для API ключей в Google Cloud Console
echo 3. Проверьте Firebase Security Rules
echo 4. Настройте квоты и алерты
echo.
echo Подробнее: см. SECURITY_ALERT.md
echo.
pause
