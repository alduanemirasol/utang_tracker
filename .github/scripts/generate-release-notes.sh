#!/usr/bin/env bash

set -euo pipefail

if [[ ! -f "$RELEASE_NOTES_JSON" ]]; then
  echo "Release notes file not found: $RELEASE_NOTES_JSON"
  exit 1
fi

category_title() {
  case "$1" in
    added) echo "Added" ;;
    changed) echo "Changed" ;;
    fixed) echo "Fixed" ;;
  esac
}

write_category() {
  local category=$1
  local title
  local notes

  title=$(category_title "$category")
  notes=$(jq -r --arg category "$category" '.notes[$category][]' "$RELEASE_NOTES_JSON")

  if [[ -z "$notes" ]]; then
    return
  fi

  echo "## $title"
  echo
  while IFS= read -r note; do
    echo "- $note"
  done <<< "$notes"
  echo
}

release_date=$(jq -r '.date' "$RELEASE_NOTES_JSON")

{
  echo "What's new in $TAG_NAME"
  echo
  echo "Release date: $release_date"
  echo
  write_category "added"
  write_category "changed"
  write_category "fixed"
} > RELEASE_NOTES.md

echo "Release notes generated."
