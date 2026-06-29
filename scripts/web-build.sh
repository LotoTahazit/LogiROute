#!/usr/bin/env bash
# Shared web build: flutter build + cache-bust patch (local + CI).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

ENV_FILE="${ENV_FILE:-.env.local}"
FLAGS=(--release --pwa-strategy=none)
if [[ -f "$ENV_FILE" ]]; then
  FLAGS=(--dart-define-from-file="$ENV_FILE" "${FLAGS[@]}")
fi

flutter pub get
flutter build web "${FLAGS[@]}"
bash "$root/patch_web_bootstrap.sh"
