#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
v="$(date +%s)"
bootstrap="$root/build/web/flutter_bootstrap.js"
sed -i.bak "s/mainJsPath\":\"main.dart.js\"/mainJsPath\":\"main.dart.js?v=$v\"/" "$bootstrap"
rm -f "${bootstrap}.bak"
echo -n "$v" > "$root/build/web/lr_epoch.txt"
