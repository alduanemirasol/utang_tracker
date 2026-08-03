#!/usr/bin/env bash

set -euo pipefail

TAG_VERSION="${TAG_NAME#v}"
APP_VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
NOTES_VERSION=$(jq -r ".version" "$RELEASE_NOTES_JSON")

if [[ "$TAG_VERSION" != "$APP_VERSION" ]]; then
  echo "Tag version does not match pubspec.yaml."
  echo "Tag: $TAG_VERSION"
  echo "App: $APP_VERSION"
  exit 1
fi

if [[ "$TAG_VERSION" != "$NOTES_VERSION" ]]; then
  echo "Tag version does not match release notes."
  echo "Tag: $TAG_VERSION"
  echo "Release notes: $NOTES_VERSION"
  exit 1
fi

echo "Version verified: $TAG_VERSION"