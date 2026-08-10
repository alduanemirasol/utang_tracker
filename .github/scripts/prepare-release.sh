#!/usr/bin/env bash

set -euo pipefail

mkdir -p "$RELEASE_DIR"

copy_apk() {
  local source_file="$1"
  local output_name="$2"

  if [[ ! -f "$source_file" ]]; then
    echo "APK not found: $source_file"
    exit 1
  fi

  cp "$source_file" "$RELEASE_DIR/$output_name"
}

copy_apk \
  "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
  "$APP_NAME-arm64-v8a-$TAG_NAME.apk"

copy_apk \
  "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" \
  "$APP_NAME-armeabi-v7a-$TAG_NAME.apk"

echo "ARM64 and ARM32 APKs prepared in $RELEASE_DIR."