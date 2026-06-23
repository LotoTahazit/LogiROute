flutter build web --dart-define-from-file=.env.local --release --pwa-strategy=none
powershell -ExecutionPolicy Bypass -File patch_web_bootstrap.ps1
firebase deploy --only hosting