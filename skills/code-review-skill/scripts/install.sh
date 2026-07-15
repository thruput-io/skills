#!/bin/bash
# Fetch the latest CODE_REVIEW.md and any referenced markdown files from the handbook repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
REFERENCES_DIR="$SKILL_DIR/references"

mkdir -p "$REFERENCES_DIR"

echo "Fetching CODE_REVIEW.md from handbook repository..."
curl -sSL "https://raw.githubusercontent.com/thruput-io/handbook/main/CODE_REVIEW.md" -o "$REFERENCES_DIR/CODE_REVIEW.md"

if [ $? -ne 0 ]; then
  echo "Failed to download CODE_REVIEW.md"
  exit 1
fi
echo "CODE_REVIEW.md successfully downloaded."

echo "Parsing CODE_REVIEW.md for additional references..."
# Find all markdown links that look like https://github.com/.../blob/... or https://raw.githubusercontent.com/...
# and download them into the references directory.
URLS=$(grep -oE 'https://(raw\.githubusercontent\.com|github\.com)/[^)"]+\.md' "$REFERENCES_DIR/CODE_REVIEW.md" | sed 's|github\.com/\(.*\)/blob/|raw.githubusercontent.com/\1/|')

if [ -n "$URLS" ]; then
  for URL in $URLS; do
    FILENAME=$(basename "$URL")
    echo "Fetching referenced file $FILENAME from $URL..."
    curl -sSL "$URL" -o "$REFERENCES_DIR/$FILENAME"
    if [ $? -eq 0 ]; then
      echo "$FILENAME successfully downloaded."
      
      # Convert raw.githubusercontent.com URL to github.com URL to make sure we match the link in the MD file
      GITHUB_URL=$(echo "$URL" | sed 's|raw\.githubusercontent\.com/\([^/]*\)/\([^/]*\)/|github.com/\1/\2/blob/|')
      
      # Rewrite the URLs in CODE_REVIEW.md to use the local cache path (references/FILENAME)
      sed "s|$URL|references/$FILENAME|g" "$REFERENCES_DIR/CODE_REVIEW.md" > "$REFERENCES_DIR/CODE_REVIEW.md.tmp" && mv "$REFERENCES_DIR/CODE_REVIEW.md.tmp" "$REFERENCES_DIR/CODE_REVIEW.md"
      sed "s|$GITHUB_URL|references/$FILENAME|g" "$REFERENCES_DIR/CODE_REVIEW.md" > "$REFERENCES_DIR/CODE_REVIEW.md.tmp" && mv "$REFERENCES_DIR/CODE_REVIEW.md.tmp" "$REFERENCES_DIR/CODE_REVIEW.md"
    else
      echo "Failed to download $URL"
    fi
  done
else
  echo "No additional references found."
fi

echo "Installation complete!"
