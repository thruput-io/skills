#!/bin/bash
# Test script to verify the skill installation and local caching

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEST_REFERENCES_DIR="$SKILL_DIR/references"

# Clean up any existing references to ensure a clean test
echo "Cleaning up existing references..."
rm -rf "$TEST_REFERENCES_DIR"

echo "Running install.sh..."
bash "$SKILL_DIR/scripts/install.sh"

if [ $? -ne 0 ]; then
  echo "❌ Test Failed: install.sh exited with non-zero status"
  exit 1
fi

# Verify files exist
FILES=("CODE_REVIEW.md" "RULES.md" "PHILOSOPHY.md")
for FILE in "${FILES[@]}"; do
  if [ ! -f "$TEST_REFERENCES_DIR/$FILE" ]; then
    echo "❌ Test Failed: $FILE was not downloaded to references/"
    exit 1
  fi
done

# Verify URL rewriting happened in CODE_REVIEW.md
if grep -q "https://github.com/thruput-io/handbook" "$TEST_REFERENCES_DIR/CODE_REVIEW.md"; then
  echo "❌ Test Failed: GitHub URLs were not rewritten to local references/ paths in CODE_REVIEW.md"
  exit 1
fi

if ! grep -q "references/RULES.md" "$TEST_REFERENCES_DIR/CODE_REVIEW.md"; then
  echo "❌ Test Failed: references/RULES.md link is missing from CODE_REVIEW.md"
  exit 1
fi

if ! grep -q "references/PHILOSOPHY.md" "$TEST_REFERENCES_DIR/CODE_REVIEW.md"; then
  echo "❌ Test Failed: references/PHILOSOPHY.md link is missing from CODE_REVIEW.md"
  exit 1
fi

echo "✅ All tests passed! Skill installation and local caching verified successfully."
