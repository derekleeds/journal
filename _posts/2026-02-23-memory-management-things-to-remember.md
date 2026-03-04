---
title: "Memory Management: Things to Remember"
date: 2026-02-23
author: derek
tags: [openclaw, memory, qmd, agent, context]
category: engineering
---

# Memory Management: Things to Remember

One of the trickiest parts of building an autonomous agent is giving it memory. Not just the ability to store data, but to actually *remember* what matters across sessions, prioritize what's important, and know when to forget. Today I'm diving into how OpenClaw handles memory - the architecture, the tools, and why we made the choices we did. 

## The Memory Problem

When you're building an agent that runs in bursts (responding to messages, handling tasks, then going dormant), you face a fundamental challenge: how do you maintain context between sessions? A human remembers their previous conversations, their preferences, the context of ongoing projects. An agent that starts fresh each time is constantly reinventing the wheel. 

We needed a memory system that could:

1. **Persist across sessions** - survive restarts and service updates
2. **Organize by importance** - not everything is equally worth remembering
3. **Stay manageable** - no one wants to dig through megabytes of chat logs to find one important detail
4. **Support both short-term and long-term** - like human memory, we need working memory for current tasks and episodic memory for past events

## How We've Set It Up

OpenClaw uses a layered memory architecture. It's not a single database or file - it's a system of interconnected storage mechanisms, each serving a different purpose.

### The Core Components

**Daily Notes** (`memory/YYYY-MM-DD.md`)
Every session that produces notable events gets recorded in time-stamped daily notes. These are raw, chronological logs of what happened - messages received, tasks completed, decisions made. Think of these as the agent's "diary" - not polished, just factual.

**Long-Term Memory** (`MEMORY.md`)
This is the curated distillation. After each session (or periodically during heartbeats), important events get distilled into this file. It's the highlights reel - the decisions, lessons, preferences, and context that should persist. We treat this file as the "true" memory that gets loaded at the start of each main session.

**The AGENTS.md Constitution**
Every agent workspace has an `AGENTS.md` file that serves as its foundational memory - who it is, what its rules are, how it should behave. This isn't memory in the episodic sense - it's more like personality and procedure combined. Every session starts by reading this file.

### Why Flat Files?

You might notice we use plain markdown files rather than a database. That's deliberate:

- **Human readability** - I can open any memory file and understand what's there
- **No additional infrastructure** - no MongoDB, Redis, or SQL needed
- **Easy to version control** - Git tracks changes naturally
- **Simple to backup** - just copy the files
- **Debuggable** - when something goes wrong, I can see exactly what's in memory

For a personal agent running in a homelab, this trade-off makes sense. We're not processing millions of memories - we're managing a few thousand lines of markdown. A database would be overkill.

## How the Memory Is Organized

The memory system follows a simple hierarchy:

```
workspace/
├── AGENTS.md          # Foundational rules and identity
├── MEMORY.md          # Long-term curated memories
├── TOOLS.md           # Local tool configurations
└── memory/
    ├── heartbeat-state.json    # Tracking periodic checks
    ├── 2026-02-20.md          # Daily notes
    ├── 2026-02-21.md
    └── 2026-02-22.md
```

The key insight is **separation of concerns**:

- **AGENTS.md** never changes based on events - it's the unchanging constitution
- **MEMORY.md** is writeable in main sessions but loadable selectively
- **Daily notes** are append-only - once written, they're historical record
- **Heartbeat state** is ephemeral tracking data that gets updated frequently

We also have a crucial security distinction: MEMORY.md is **only loaded in main sessions** (direct chats with the human). In shared contexts like group chats or Discord, the agent doesn't load personal context. This prevents accidentally leaking private information to strangers - a genuine concern when your agent participates in group conversations.

## How Clawdia Is Now Using QMD

This is the recent change that prompted this post. We recently migrated from traditional markdown to **QMD** (Quarto Markdown) for certain memory files.

QMD adds YAML metadata blocks at the top of markdown files, along with enhanced formatting capabilities. The frontmatter looks like:

```yaml
---
title: "Session Notes"
date: 2026-02-23
tags: [openclaw, session]
category: memory
---
```

### Why QMD?

Several practical reasons:

1. **Metadata tagging** - Each file now carries its own metadata, making it easier to query and organize
2. **Future-proofing** - If we ever want to generate reports or dashboards from memory data, QMD plays nicely with Quarto's tooling
3. **Consistency** - Our blog posts already use QMD frontmatter, so memory files matching that format feels natural
4. **Extensibility** - We can add custom fields as needs evolve (priority, sentiment, related-tasks)

The migration wasn't painful - we wrote a small script to add frontmatter to existing files. The payoff is a more organized, more queryable memory system going forward.

## The Benefits

After several months of running this system, here's what we've gained:

### Continuity Without Overhead

The agent genuinely remembers previous conversations. It knows about ongoing projects, past decisions, and my preferences. But it doesn't drag around megabytes of context - it loads what's relevant and leaves the rest.

### Heartbeat-Friendly

The periodic heartbeat system (running checks every ~30 minutes) uses the memory system to track state. We maintain a `heartbeat-state.json` that tracks when we last checked emails, calendar, weather, etc. This prevents redundant work and lets the agent be genuinely helpful without being annoying.

### Debuggability

When the agent does something unexpected, I can trace through the memory files and understand what context it was working with. No black boxes - everything is readable text.

### Security by Default

The separation between main-session and shared-context memory means the agent can't accidentally share private context. It's not a configuration flag that can be forgotten - it's architecturally enforced.

### Human-Readable Audit Trail

Every decision, every important event, every lesson learned gets recorded. I can look back at any day's notes and see exactly what happened. It's like having a detailed operating log for an autonomous system.

## What We'd Do Differently

Honesty time - if we were rebuilding this:

1. **Search functionality** - Currently, finding something means grepping through files. A simple index or tagging system would help.
2. **Automatic pruning** - Old daily notes accumulate. We should have a policy to archive or compress notes older than X months.
3. **Memory retrieval scoring** - Not all memories are equally relevant. A system that scores context by relevance (rather than just recency) would improve response quality.

These are on the roadmap, but the current system works well enough that they've been lower priority.

## The Bottom Line

Memory management for autonomous agents isn't just about storage - it's about giving the agent a sense of self and continuity. We've built a system that's simple (flat files), intentional (curated over accumulated), and practical (human-readable, debuggable, secure).

The QMD migration is a small change, but it represents an ongoing commitment to keeping the memory system organized as the agent grows more capable. Because at the end of the day, an agent is only as good as what it remembers.