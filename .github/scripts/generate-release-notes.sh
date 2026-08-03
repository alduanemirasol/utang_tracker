#!/usr/bin/env bash

set -euo pipefail

if [[ ! -f "$RELEASE_NOTES_JSON" ]]; then
  echo "Release notes file not found: $RELEASE_NOTES_JSON"
  exit 1
fi

{
  echo "What's new in $TAG_NAME"
  echo
  jq -r '.notes[] | "- \(.)"' "$RELEASE_NOTES_JSON"
} > RELEASE_NOTES.md

echo "Release notes generated."