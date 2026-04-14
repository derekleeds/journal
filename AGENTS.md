# AGENTS.md - Journal Repository Guide

This file provides context for AI agents working with the `derekleeds/journal` repository.

## Overview

**Purpose:** Derek's learning documentation and blog  
**URL:** https://journal.derekleeds.cloud  
**Tech Stack:** Jekyll (Markdown → Static HTML)  
**Hosting:** GitHub Pages  
**Workflow:** Obsidian → MarkItDown → Journal → Published

## Repository Structure

```
journal/
├── _posts/           # Blog posts (YYYY-MM-DD-slug.md format)
├── _pages/           # Static pages (About, etc.)
├── _tags/            # Tag index pages
├── _includes/        # Reusable templates
├── _data/            # Data files (navigation, etc.)
├── assets/           # Images, CSS, JS
├── _config.yml       # Jekyll configuration
└── Gemfile           # Ruby dependencies
```

## Post Format

All posts are Markdown with YAML frontmatter:

```yaml
---
title: "Post Title"
date: 2026-04-14
description: "Brief description for SEO"
categories:
  - Category Name
tags:
  - tag1
  - tag2
draft: false  # Set true for drafts
---

Post content in Markdown...
```

### Post Filename Convention

`YYYY-MM-DD-slug.md` — Date must match the `date:` in frontmatter.

## Publishing Workflow

1. **Draft in Obsidian** → MarkItDown processes markdown
2. **Move to `_posts/`** → Filename: `YYYY-MM-DD-slug.md`
3. **Commit and push** → GitHub Pages auto-deploys (~30 seconds)
4. **Live at:** `https://journal.derekleeds.cloud/YYYY/MM/DD/slug/`

### Migration Script

Use `migrate-posts.sh` to batch-move drafts:

```bash
./migrate-posts.sh
```

## Content Guidelines

- **Voice:** First-person, learning-focused, practical
- **Audience:** Derek's future self + others learning the same topics
- **Tone:** Concise, technical but accessible, no AI hype
- **Length:** 500-2000 words typical
- **Code blocks:** Use triple backticks with language specifier
- **Images:** Store in `assets/`, reference with relative paths

## Technical Details

### Jekyll Version
- Defined in `Gemfile` and `_config.yml`
- Ruby 3.x required

### Local Development

```bash
# Install dependencies
bundle install

# Run local server
bundle exec jekyll serve

# Access at: http://localhost:4000
```

### Build Verification

Before pushing, verify the build works:

```bash
bundle exec jekyll build
```

If build fails, check:
- Frontmatter syntax (YAML is strict)
- Filename date matches frontmatter date
- No broken Liquid tags

## Common Tasks

### Create New Post

1. Create file: `_posts/YYYY-MM-DD-slug.md`
2. Add frontmatter (title, date, description, categories, tags)
3. Write content
4. Test locally: `bundle exec jekyll serve`
5. Commit and push

### Update Existing Post

1. Edit the markdown file in `_posts/`
2. Commit with descriptive message
3. Push — GitHub Pages auto-deploys

### Add New Tag

1. Create file: `_tags/tag-name.md`
2. Add frontmatter:
   ```yaml
   ---
   layout: tag
   tag: tag-name
   title: "Tag: tag-name"
   ---
   ```
3. Commit and push

## Agent Instructions

When working with this repo:

1. **Always read existing posts** in `_posts/` to match style
2. **Verify frontmatter** — Jekyll is strict about YAML syntax
3. **Check filenames** — Date in filename must match frontmatter `date:`
4. **Test builds locally** before pushing if possible
5. **Never delete old posts** — They're permanent records
6. **Preserve URLs** — Changing slugs breaks existing links

## Related Repositories

- **guides.derekleeds.cloud** — Technical guides (Hugo + Docsy)
- **Obsidian Vault** — Source of truth for notes (not in git)
- **MarkItDown** — Conversion tool (local script)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails | Check YAML frontmatter syntax |
| Post not showing | Verify `draft: false` and date is not in future |
| 404 on post | Check filename format matches date |
| Images broken | Verify path in `assets/` is correct |

## Contact

For questions or issues, contact Derek Leeds:
- Email: contact@derekleeds.com
- GitHub: @derekleeds

---

*Last updated: 2026-04-14*
