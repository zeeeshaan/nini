#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

API_BASE_URL="${API_BASE_URL:-http://35.154.187.106/api}"
OUT_DIR="${OUT_DIR:-dist}"
mkdir -p "$OUT_DIR"

echo "Building HYWORK client APK…"
echo "API_BASE_URL=$API_BASE_URL"

flutter build apk --release \
  --dart-define="API_BASE_URL=$API_BASE_URL" \
  --dart-define=ALLOW_HTTP_API=true

SRC="build/app/outputs/flutter-apk/app-release.apk"
DEST="$OUT_DIR/hywork-client-$(date +%Y%m%d).apk"
cp "$SRC" "$DEST"
cp "$SRC" "$OUT_DIR/hywork-client-latest.apk"

ls -lh "$SRC" "$DEST" "$OUT_DIR/hywork-client-latest.apk"
echo "Client APK ready: $DEST"
