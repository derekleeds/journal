#!/bin/bash
# Copy Markdown files for AI agent access
# Run as post-build hook: bundle exec jekyll build && bash bin/copy-markdown.sh

echo "=========================================="
echo "Copying Markdown files for AI agents..."
echo "=========================================="

# Copy posts (strip date prefix from filename)
find _posts \( -name "*.md" -o -name "*.markdown" \) | while read file; do
  filename=$(basename "$file")
  if [[ $filename =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.+)\.(md|markdown)$ ]]; then
    slug="${BASH_REMATCH[4]}"
    target="_site/${slug}.md"
    cp "$file" "$target"
    echo "✓ Copied: $filename -> $target"
  fi
done

# Copy pages (preserve name)
if [ -d "_pages" ]; then
  find _pages \( -name "*.md" -o -name "*.markdown" \) | while read file; do
    filename=$(basename "$file" .md)
    if [[ "$filename" != "index" ]]; then
      target="_site/${filename}.md"
      cp "$file" "$target"
      echo "✓ Copied page: $(basename $file) -> $target"
    fi
  done
fi

echo "=========================================="
echo "Markdown files ready for AI agents!"
echo "=========================================="
ls -la _site/*.md 2>/dev/null | wc -l | xargs echo "Total .md files in _site:"
