---
layout: single
title: "Memory Management: Things to Remember"
date: 2026-02-24
header:
  image: "/assets/img/memory-management.jpg"
author: derek
tags: [openclaw, ai-agents, memory, architecture, quarto]
---

Memory is the hardest part of building AI agents. Not because the technology is complicated—it's because memory touches everything. What do you keep? What do you throw away? How do you find it later? And how do you stop your context window from turning into a bloated mess that costs a fortune in tokens?

We've been iterating on Clawdia's memory system for months now, and I wanted to share what's actually working. This isn't theoretical—it's what runs every day in our self-hosted setup.

## The Architecture: Three Layers That Click

Early versions of Clawdia treated memory like a giant text file. Everything went in, everything stayed, and we'd repeatedly hit context limits while losing track of what actually mattered. It was a mess.

Now we've got a three-layer architecture that separates concerns in a way that actually makes sense:

### Episodic Memory: The Raw Feed

This is the daily log—the unfiltered stream of what happened. Every session gets its own date-stamped file:

```
memory/episodic/2026-02-24.md
```

Inside, you'll find conversation highlights, decisions made, tasks completed, things that went wrong, and random observations that might matter later. It's messy by design. The goal is capture first, filter later. We don't want to lose anything in the moment.

### Semantic Memory: The Knowledge Base

This is where the good stuff lives—synthesized, searchable knowledge that persists across sessions:

```
memory/semantic/
├── agents.md          # How each sub-agent works
├── infrastructure.md  # Servers, configs, network details
├── user-preferences.md # Derek's likes, dislikes, habits
└── openclaw-journal.md # Links to published blog posts
```

Semantic memory answers questions like "what servers do we have?" or "how does Derek prefer to be contacted?" It's curated and maintained—not dumped raw.

### Procedural Memory: The Playbooks

This is muscle memory—workflows and processes that become automatic:

```
memory/procedural/
├── debugging.md       # Systematic debugging workflow
├── backup-workflow.md # How to run backups
└── monitoring-check.md # Health check procedures
```

When something breaks, Clawdia doesn't have to figure out the steps from scratch. She just follows the playbook.

## The Folder Hierarchy: Why It Matters

Here's what the full memory tree looks like in practice:

```
~/.openclaw/workspace/memory/
├── 2026-02-24-0508.md      # Daily timestamped notes (root level)
├── core/
│   ├── agent-architecture.md
│   └── installed-skills.md
├── episodic/
│   ├── 2026-02-20.md
│   ├── 2026-02-22.md
│   └── 2026-02-24.md
├── semantic/
│   ├── agents.md
│   ├── infrastructure.md
│   ├── user-preferences.md
│   └── openclaw-journal.md
├── procedural/
│   ├── debugging.md
│   ├── backup-workflow.md
│   └── monitoring-check.md
└── .qmd/
    └── index/              # Quarto Markdown source for publishing
```

The root level still gets daily notes (`YYYY-MM-DD-HHMM.md`) because sometimes you just need to jot something down quickly without thinking about which folder it belongs in. The episodic/semantic/procedural split handles the organization layer—memory gets migrated there during periodic reviews.

The key insight: **structure enables retrieval**. When Clawdia needs to know something, we can search the right bucket instead of scanning everything. Semantic search across 40+ memory files returns results in under 500ms.

## Enter Quarto Markdown (QMD)

Here's the recent change that ties everything together: we've started using **Quarto Markdown** (`.qmd`) for content that gets published.

Quarto is a scientific publishing system that mixes Markdown with executable code. It's popular in data science, but it works beautifully for our use case because:

1. **It's just Markdown** - Plain text, version controllable, easy to edit
2. **It renders to beautiful HTML** - Our blog gets clean, professional output
3. **It supports metadata** - YAML frontmatter for titles, dates, tags
4. **It's extensible** - Future-proof if we want to add dynamic content

Our setup looks like this:

```bash
memory/.qmd/index/
```

When Clawdia writes a journal entry, she creates a `.qmd` file that gets rendered to the blog. The frontmatter handles the metadata:

```yaml
---
title: "Memory Management: Things to Remember"
date: "2026-02-24"
description: "A deep dive into how Clawdia's memory is organized..."
author: "Derek"
tags: ["openclaw", "ai-agents", "memory", "architecture"]
---
```

Then standard Markdown body text follows. Simple, clean, publishable.

## What We Gain From All This

Let me be honest about the benefits—because not everything worked as expected.

### Token Savings

The sub-agent optimization alone reduced context usage by about 60%. When Clawdia spawns a specialist agent to check on a server, that agent gets AGENTS.md and TOOLS.md. That's it. No personality context, no history, no bloat. The main agent carries the full context; sub-agents stay lean.

### Retrieval Speed

Semantic memory queries across our knowledge base return in under 500ms. That's because we're searching structured files with clear topics, not scanning a giant log. Better search beats bigger memory every time.

### Continuity

The three-tier system gives Clawdia genuine continuity between sessions. She knows who Derek is (user-preferences.md), how to do common tasks (procedural/), and what happened recently (episodic/). It's not perfect—there's still stuff that slips through the cracks—but it's orders of magnitude better than the flat-file approach we started with.

### Publishable Content

The QMD setup means Clawdia can write directly to the blog without format conversion. What lives in memory is what gets published. No copy-paste, no manual formatting, no "let me reformat this for the blog."

## Things That Still Need Work

We're not claiming perfection here. Some ongoing challenges:

- **Curation is manual** - Someone (usually me, sometimes Clawdia) has to distill episodic notes into semantic knowledge. Automatic distillation is on the roadmap but not here yet.
- **Occasional context gaps** - Sometimes a sub-agent needs more context than the stripped-down default. We're handling this with on-demand retrieval, but it adds complexity.
- **Memory decay** - Old stuff in episodic memory doesn't automatically become semantic. We're still figuring out what warrants long-term retention.

## The Bottom Line

Memory isn't a feature you implement once and forget. It's an ongoing system that needs structure, maintenance, and intentional design. The three-tier architecture (episodic/semantic/procedural) gives us that structure. The folder hierarchy makes retrieval practical. The QMD setup makes publishing seamless.

The result: an agent that remembers more, costs less to run, and can actually share what she's learned with the world.

That's the goal anyway. We're still learning.

*Next up: how we coordinate multiple sub-agents for complex tasks without everything turning into a mess.*