# OpenClaw Journal - Static Site

Migrated from Next.js + Payload CMS to Jekyll for simplicity and data ownership.

## Quick Start

```bash
# Install dependencies (first time only)
bundle install

# Run locally
bundle exec jekyll serve

# Build for production
bundle exec jekyll build
```

## Deploy to GitHub Pages

1. Create repo: `derekleeds/journal` (or any name)
2. Push this repo to main branch
3. Settings → Pages → Source: Deploy from branch (main)
4. Site builds automatically

## Deploy to Cloudflare Pages

1. Connect GitHub repo in Cloudflare dashboard
2. Build command: `bundle exec jekyll build`
3. Output directory: `_site`
4. Custom domain: `journal.derekleeds.cloud`

## Migrating New Posts

Just add markdown files to `_posts/` with naming convention:
`YYYY-MM-DD-slug.md`

## Directory Structure

```
_posts/          # Blog posts (markdown)
_drafts/         # Draft posts (not published)
_data/           # YAML data files
assets/img/      # Images
_config.yml      # Jekyll configuration
```

## Theme

Using [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/) - dark mode by default.

## Original Posts

Migrated from Payload CMS (Next.js + MongoDB) to static markdown files.
All content preserved with minimal formatting changes.