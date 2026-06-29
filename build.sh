#!/usr/bin/env bash
# LogiRoute: web | web-deploy | apk | all | clean
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"

ENV_FILE="${ENV_FILE:-.env.local}"
APK_FLAGS=(--release --dart-define-from-file="$ENV_FILE")

cmd_web() {
  bash "$root/scripts/web-build.sh"
}

cmd_web_deploy() {
  cmd_web
  firebase deploy --only hosting
}

cmd_apk() {
  flutter build apk "${APK_FLAGS[@]}"
}

cmd_clean() {
  flutter clean
  flutter pub get
}

cmd_all() {
  cmd_clean
  cmd_web
  cmd_apk
}

cmd_full() {
  cmd_all
  firebase deploy
}

cmd_patch() {
  bash "$root/patch_web_bootstrap.sh"
}

usage() {
  echo "Usage: ./build.sh {web|web-deploy|apk|all|full|patch|clean}"
  exit 1
}

case "${1:-}" in
  web) cmd_web ;;
  web-deploy) cmd_web_deploy ;;
  apk) cmd_apk ;;
  all) cmd_all ;;
  full) cmd_full ;;
  patch) cmd_patch ;;
  clean) cmd_clean ;;
  *) usage ;;
esac
