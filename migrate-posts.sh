#!/bin/bash
# Migrate posts from Payload CMS format to Jekyll format
# Usage: ./migrate-posts.sh

SOURCE_DIR="$HOME/openclaw-journal/content/posts"
TARGET_DIR="$HOME/openclaw-journal-static/_posts"

mkdir -p "$TARGET_DIR"

for f in "$SOURCE_DIR"/*.md; do
  if [ -f "$f" ]; then
    filename=$(basename "$f")
    
    # Extract date from frontmatter (line starting with "date:")
    date=$(grep "^date:" "$f" | head -1 | awk '{print $2}')
    
    # Remove image and draft from frontmatter (Payload-specific)
    # Keep title, date, author, tags, category
    
    # Create temp file with cleaned frontmatter
    temp_file=$(mktemp)
    
    # Copy everything except image and draft lines
    sed '/^image:/d; /^draft:/d' "$f" > "$temp_file"
    
    # Rename to Jekyll convention: YYYY-MM-DD-slug.md
    new_name="${date}-${filename}"
    
    cp "$temp_file" "$TARGET_DIR/$new_name"
    rm "$temp_file"
    
    echo "Migrated: $filename → $new_name"
  fi
done

echo ""
echo "Done! Posts migrated to: $TARGET_DIR"
echo ""
echo "Next steps:"
echo "  1. cd ~/openclaw-journal-static"
echo "  2. bundle install"
echo "  3. bundle exec jekyll serve"
echo "  4. Open http://localhost:4000"