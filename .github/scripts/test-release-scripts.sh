#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

generate_notes() {
  local fixture=$1
  local output_dir=$2
  mkdir -p "$output_dir"
  (
    cd "$output_dir"
    TAG_NAME=v1.0.35 \
      RELEASE_NOTES_JSON="$fixture" \
      bash "$REPO_ROOT/.github/scripts/generate-release-notes.sh"
  )
}

assert_contains() {
  local expected=$1
  local file=$2
  grep -qF "$expected" "$file"
}

assert_no_category_headings() {
  local file=$1
  if grep -Eq '^## (Added|Changed|Fixed)$' "$file"; then
    echo "Empty release note categories were rendered in $file."
    exit 1
  fi
}

cat > "$TEST_DIR/mixed.json" <<'JSON'
{"version":"1.0.35","date":"2026-08-05","notes":{"added":["New item"],"changed":["Changed item"],"fixed":["Fixed item"]}}
JSON
generate_notes "$TEST_DIR/mixed.json" "$TEST_DIR/mixed"
mixed_output="$TEST_DIR/mixed/RELEASE_NOTES.md"
assert_contains "Release date: 2026-08-05" "$mixed_output"
assert_contains "## Added" "$mixed_output"
assert_contains "## Changed" "$mixed_output"
assert_contains "## Fixed" "$mixed_output"

cat > "$TEST_DIR/changed.json" <<'JSON'
{"version":"1.0.35","date":"2026-08-05","notes":{"added":[],"changed":["Changed item"],"fixed":[]}}
JSON
generate_notes "$TEST_DIR/changed.json" "$TEST_DIR/changed"
changed_output="$TEST_DIR/changed/RELEASE_NOTES.md"
assert_contains "## Changed" "$changed_output"
if grep -Eq '^## (Added|Fixed)$' "$changed_output"; then
  echo "Empty Added or Fixed category was rendered in $changed_output."
  exit 1
fi

cat > "$TEST_DIR/empty.json" <<'JSON'
{"version":"1.0.35","date":"2026-08-05","notes":{"added":[],"changed":[],"fixed":[]}}
JSON
generate_notes "$TEST_DIR/empty.json" "$TEST_DIR/empty"
assert_no_category_headings "$TEST_DIR/empty/RELEASE_NOTES.md"

echo "Release script tests passed."
