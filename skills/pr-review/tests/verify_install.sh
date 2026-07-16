#!/bin/bash
# Smoke test for install.sh: runs it against an empty references/ dir and verifies
# that CODE_REVIEW.md is present and that every referenced .md link was rewritten
# to a local path that actually exists.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
REFERENCES_DIR="$SKILL_DIR/references"

echo "Cleaning references/..."
rm -rf "$REFERENCES_DIR"

echo "Running install.sh..."
bash "$SKILL_DIR/scripts/install.sh"

if [ ! -f "$REFERENCES_DIR/CODE_REVIEW.md" ]; then
  echo "FAIL: CODE_REVIEW.md was not created" >&2
  exit 1
fi

# No remaining external handbook links.
if grep -qE 'https://(raw\.githubusercontent\.com|github\.com)/thruput-io/handbook' \
    "$REFERENCES_DIR/CODE_REVIEW.md"; then
  echo "FAIL: external handbook URLs remain in CODE_REVIEW.md — rewrite pass missed something" >&2
  exit 1
fi

# Every local references/<file>.md link must resolve to a real file.
MISSING=0
while IFS= read -r REL; do
  if [ ! -f "$SKILL_DIR/$REL" ]; then
    echo "FAIL: link -> $REL but file is missing" >&2
    MISSING=1
  fi
done < <(grep -oE 'references/[A-Za-z0-9_.-]+\.md' "$REFERENCES_DIR/CODE_REVIEW.md" | sort -u)

if [ "$MISSING" -ne 0 ]; then
  exit 1
fi

echo "PASS"
