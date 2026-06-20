#!/bin/bash
set -euo pipefail
ENV_FILE="${ENV_FILE:-.env.local}"
INDEX="web/index.html"
PLACEHOLDER="YOUR_GOOGLE_MAPS_WEB_KEY"

if [[ -f "$ENV_FILE" ]]; then
  KEY=$(grep -E '^GOOGLE_MAPS_WEB_KEY=' "$ENV_FILE" | cut -d= -f2- | tr -d '\r')
  if [[ -n "$KEY" && "$KEY" != "your_web_api_key_here" ]]; then
    sed -i.bak "s/${PLACEHOLDER}/${KEY}/g" "$INDEX"
    trap 'mv -f "${INDEX}.bak" "$INDEX"' EXIT
  fi
fi

flutter build web --dart-define-from-file="$ENV_FILE"
