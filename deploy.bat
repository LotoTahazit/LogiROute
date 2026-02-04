@echo off
echo 🚀 Building and deploying LogiRoute Web...
echo.

echo 📦 Step 1: Building Flutter Web (production)...
call flutter build web
if %errorlevel% neq 0 (
    echo ❌ Build failed!
    exit /b %errorlevel%
)

echo.
echo 🔥 Step 2: Deploying to Firebase Hosting...
call firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ❌ Deploy failed!
    exit /b %errorlevel%
)

echo.
echo ✅ Deployment successful!
echo 🌐 Check your site at: https://your-project.web.app

