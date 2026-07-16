#!/bin/bash
# Fetch CODE_REVIEW.md and any referenced markdown files from the handbook repository
# into references/, and rewrite links so they resolve to the local cache.
#
# This is NOT automatically executed by `npx skills add/install`. SKILL.md tells the
# agent to run this on first use or when the user asks to refresh the handbook.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
REFERENCES_DIR="$SKILL_DIR/references"
HANDBOOK_RAW_BASE="https://raw.githubusercontent.com/thruput-io/handbook/main"

mkdir -p "$REFERENCES_DIR"

# Escape a string so it's safe on the LHS of `sed s|...|...|`.
sed_escape_lhs() { printf '%s' "$1" | sed -e 's/[][\/.^$*|]/\\&/g'; }
# Escape a string so it's safe on the RHS of `sed s|...|...|`.
sed_escape_rhs() { printf '%s' "$1" | sed -e 's/[\/&|]/\\&/g'; }

echo "Fetching CODE_REVIEW.md from handbook..."
curl --fail -sSL "$HANDBOOK_RAW_BASE/CODE_REVIEW.md" -o "$REFERENCES_DIR/CODE_REVIEW.md"
echo "  ok"

echo "Scanning for referenced markdown files..."
# Match both raw.githubusercontent.com and github.com/.../blob/... links to .md files.
URLS=$(grep -oE 'https://(raw\.githubusercontent\.com|github\.com)/[^)"[:space:]]+\.md' \
  "$REFERENCES_DIR/CODE_REVIEW.md" | sort -u || true)

if [ -z "$URLS" ]; then
  echo "  none found"
  echo "Done."
  exit 0
fi

# First pass: download every referenced file.
declare -a ORIGINAL_URLS=()
declare -a LOCAL_PATHS=()
while IFS= read -r URL; do
  [ -z "$URL" ] && continue
  RAW_URL=$(echo "$URL" | sed 's|github\.com/\([^/]*\)/\([^/]*\)/blob/|raw.githubusercontent.com/\1/\2/|')
  FILENAME=$(basename "$RAW_URL")
  echo "  fetching $FILENAME"
  if curl --fail -sSL "$RAW_URL" -o "$REFERENCES_DIR/$FILENAME"; then
    ORIGINAL_URLS+=("$URL")
    LOCAL_PATHS+=("references/$FILENAME")
    # Also register the raw form if the doc references it directly.
    if [ "$RAW_URL" != "$URL" ]; then
      ORIGINAL_URLS+=("$RAW_URL")
      LOCAL_PATHS+=("references/$FILENAME")
    fi
  else
    echo "  WARN: failed to fetch $RAW_URL — leaving link intact" >&2
  fi
done <<< "$URLS"

# Second pass: rewrite all URLs in a single sed invocation to avoid ordering issues.
if [ "${#ORIGINAL_URLS[@]}" -gt 0 ]; then
  SED_ARGS=()
  for i in "${!ORIGINAL_URLS[@]}"; do
    LHS=$(sed_escape_lhs "${ORIGINAL_URLS[$i]}")
    RHS=$(sed_escape_rhs "${LOCAL_PATHS[$i]}")
    SED_ARGS+=(-e "s|$LHS|$RHS|g")
  done
  sed "${SED_ARGS[@]}" "$REFERENCES_DIR/CODE_REVIEW.md" > "$REFERENCES_DIR/CODE_REVIEW.md.tmp"
  mv "$REFERENCES_DIR/CODE_REVIEW.md.tmp" "$REFERENCES_DIR/CODE_REVIEW.md"
fi

echo "Done."
