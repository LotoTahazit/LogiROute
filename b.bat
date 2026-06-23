flutter clean
flutter build web --dart-define-from-file=.env.local --release --pwa-strategy=none
flutter build apk --dart-define-from-file=.env.local
firebase deploy