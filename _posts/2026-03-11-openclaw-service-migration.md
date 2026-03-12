---
layout: single
classes: wide
title: "OpenClaw Service Migration: From pnode200 to openclaw-node01"
date: 2026-03-11
author: derek
tags: [homelab, openclaw, migration, docker, tailscale, discrawl]
---

What started as a routine cron job review turned into a full infrastructure migration session. Here's how we moved core OpenClaw services from pnode200 to openclaw-node01 in a single evening.

## The Trigger

We discovered that QMD memory sync was still running on pnode200 - the old OpenClaw host. The sync was pushing outdated workspace content to MS-S1-MAX. That kicked off a review of what else was running on pnode200 that should have been on openclaw-node01.

## Cron Jobs

### What Was Still on pnode200

| Job | Schedule | Why It Matters |
|-----|----------|----------------|
| Whisper-watch | Every 5 min | Audio transcription queue |
| Memory distill | Sunday 22:00 | Weekly knowledge consolidation |
| Workspace → Obsidian | Daily 06:00 | Note synchronization |

All still running on old hardware, syncing content that was increasingly stale.

### What Was Missing

OpenClaw cron jobs hadn't been fully set up on the new host:

- Morning Briefing at 08:00 Mon-Fri
- QMD Index Maintenance at 06:30 daily

We added all of these to openclaw-node01's crontab.

### The SSH Key Detail

The QMD sync needed SSH access from openclaw-node01 to MS-S1-MAX. One `ssh-copy-id` later and the memory sync was running on the right machine.

## Container Migration

### markitdown-mcp

Microsoft's MarkItDown MCP server - converts PDFs, DOCX, PPTX to Markdown. Built from source:

```bash
git clone https://github.com/microsoft/markitdown.git
cd markitdown/packages/markitdown-mcp
docker build -t markitdown-mcp:0.1.0 .
```

This is a document ingestion tool for agents. PDF extraction works well. YouTube transcripts are hit-or-miss due to anti-bot measures.

### yt-dlp

Not a persistent service - this is CLI-only. The container exits immediately. Running `docker compose up -d` causes restart loops.

Instead, use the wrapper script:

```bash
/opt/stacks/yt-dlp/yt-dlp-wrap.sh "https://youtube.com/watch?v=VIDEO_ID"
```

Downloads to `~/workspace/downloads/`.

### mkdocs-material

This one mattered for Tailscale integration.

The old instance on pnode200 was hosting the docs site at `docs.tailbd8f6.ts.net`. We needed to:

1. Stop the container on pnode200
2. Sync the docs content via rsync
3. Start the new container on openclaw-node01 with Docktail labels
4. Tag openclaw-node01 in Tailscale with `tag:server`

Docktail reads the container labels and creates Tailscale Funnel services automatically. Once the node had the right tag, `docs.tailbd8f6.ts.net` pointed to the new host.

### What We Skipped

- **openclaw-dashboard** - Phase 1 was rough, not ready
- **apprise-notification-server** - Future use only
- **rackpeek** - Not fully functional

## discrawl: Discord Archive Search

This was the evening's bonus. [discrawl](https://github.com/steipete/discrawl) mirrors Discord into SQLite for local search.

```bash
brew tap steipete/tap
brew install steipete/tap/discrawl
discrawl init --from-openclaw ~/.openclaw/openclaw.json
discrawl sync --full
```

It pulled 113,842 messages from the #openclaw guild. Now we can search locally:

```bash
discrawl search "migration" --channel openclaw
```

The `--from-openclaw` flag reuses OpenClaw's Discord bot token, so no separate configuration needed.

We set it up as a systemd service to tail live events:

```bash
sudo systemctl enable --now discrawl-tail
```

Now every message gets archived in real-time.

## Go and Homebrew

discrawl required Go 1.26+. Installed via Homebrew:

```bash
brew install go
# go version go1.26.1 linux/amd64
```

Had to add `--break-system-packages` for AgentMail's Python package on Ubuntu 24.04. The PEP 668 restrictions caught us there.

## What Else

- Created `.gitignore` for the workspace - `.env` was not being ignored (!)
- Documented MCP code mode pattern for reducing context bloat
- Fixed AgentMail Python package installation
- Added context-hub skill for API documentation fetching

## The Numbers

| Metric | Count |
|--------|-------|
| Containers deployed | 5 |
| Cron jobs migrated/added | 8 |
| Tailscale services exposed | 1 |
| Messages in discrawl | 113,842 |
| Session duration | ~2 hours |

## Lessons Learned

1. **Docktail needs node tags** - Tailscale Services require `tag:server` on the host before they'll create
2. **yt-dlp is CLI-only** - Don't run as a service
3. **Ubuntu 24.04 + pip** - The `--break-system-packages` flag is necessary
4. **MCP context bloat is real** - We documented a pattern for future reference

## What's Next

- Wire discrawl into the agent research workflow
- Migrate remaining containers (dashboard, apprise, rackpeek) when ready
- Monitor discrawl-tail for stability over longer runs

---

*Session duration: approximately 2 hours*