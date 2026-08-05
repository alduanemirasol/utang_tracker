#!/usr/bin/env bash

set -euo pipefail

TAG_VERSION="${TAG_NAME#v}"
APP_VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
NOTES_VERSION=$(jq -r ".version" "$RELEASE_NOTES_JSON")

validate_release_notes_schema() {
  jq -e '
    type == "object" and
    (.version | type == "string") and
    (.date | type == "string") and
    (.notes | type == "object") and
    (.notes.added | type == "array" and all(.[]; type == "string")) and
    (.notes.changed | type == "array" and all(.[]; type == "string")) and
    (.notes.fixed | type == "array" and all(.[]; type == "string"))
  ' "$RELEASE_NOTES_JSON" > /dev/null
}

validate_release_date() {
  local notes_date
  local parsed_date

  notes_date=$(jq -r '.date' "$RELEASE_NOTES_JSON")
  parsed_date=$(date -d "$notes_date" +%F 2>/dev/null || true)

  if [[ ! "$notes_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    return 1
  fi

  [[ "$parsed_date" == "$notes_date" ]]
}

if ! validate_release_notes_schema; then
  echo "Release notes do not match the required schema."
  exit 1
fi

if ! validate_release_date; then
  echo "Release notes date must be a valid date in YYYY-MM-DD format."
  exit 1
fi

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
