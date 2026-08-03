#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${SIGNING_KEY_BASE64:-}" ]]; then
  echo "SIGNING_KEY_BASE64 is missing."
  exit 1
fi

if [[ -z "${KEY_STORE_PASSWORD:-}" ]]; then
  echo "KEY_STORE_PASSWORD is missing."
  exit 1
fi

if [[ -z "${KEY_PASSWORD:-}" ]]; then
  echo "KEY_PASSWORD is missing."
  exit 1
fi

if [[ -z "${KEY_ALIAS:-}" ]]; then
  echo "KEY_ALIAS is missing."
  exit 1
fi

echo "$SIGNING_KEY_BASE64" |
  base64 --decode > android/app/release.keystore

cat > android/key.properties <<EOF
storePassword=$KEY_STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=app/release.keystore
EOF

echo "Android signing configured."