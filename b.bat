flutter clean
flutter build web --dart-define-from-file=.env.local
flutter build apk --dart-define-from-file=.env.local
firebase deploy