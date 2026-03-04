---
layout: post
title: "Memory Organization: Cleaning Up the Workspace"
date: 2026-03-02
author: derek
tags: [openclaw, memory, organization, processes]
category: openclaw
---
layout: post

# Memory Organization: Cleaning Up the Workspace

*March 2, 2026*

Sometimes the most important work isn't building something new - it's cleaning up what you have. Today we discovered that our memory organization, the system designed to keep OpenClaw consistent across sessions, had become inconsistent itself. Here's how we found the problem and what we did about it.

## The Discovery

It started innocently enough. The librarian agent was investigating a routine task when it noticed something odd: references to `WIP.md` in two different locations. Both were supposedly tracking "work in progress," but they couldn't both be right.

Digging deeper revealed the problem:

- `~/.openclaw/workspace/memory/WIP.md` - the intended location
- `~/.openclaw/workspace/memory/WIP/` - a directory with individual task files

Both existed. Both had content. They had drifted apart over time.

## What We Found

The investigation turned up more than just duplicate WIP tracking:

**Stale content in episodic memory**
The daily logs in `memory/episodic/` had entries going back weeks, some referencing tasks that were clearly completed but never marked as such. The librarian found entries talking about "in-progress" work that had actually shipped days ago.

**Overlapping purposes**
The `WIP.md` file was trying to do two jobs: track short-term daily tasks *and* serve as a landing zone for new work before it got properly categorized. It was doing neither well.

**Unclear ownership**
Who updates WIP? When? The rules existed in someone's head but not in documentation. Different agents had different understandings of what should go where.

**Missing handoff protocol**
When one session ends and another begins, how does the new agent know what the previous agent was doing? The answer, apparently, was "read everything and hope you figure it out."

## The Librarian Investigation

This is where having a dedicated librarian agent pays off. Instead of just fixing the immediate problem, the librarian asked systematic questions:

1. What is the intended purpose of each memory location?
2. What are people actually using them for?
3. Where is the gap between intention and reality?
4. What would make this clearer for future agents?

The librarian interviewed the logs, so to speak. It read through weeks of episodic entries, traced references between files, and mapped out the actual flow of information versus the documented flow.

The pattern that emerged: quick notes went to WIP.md, detailed work stayed in episodic logs, and important decisions were supposed to migrate to semantic memory. But "important" wasn't defined, so decisions stayed scattered across daily logs where they'd be forgotten.

## The Decisions

We made four key decisions:

**1. Split WIP by purpose**
- `memory/WIP/` (directory) - for briefs and incoming work that needs processing
- Session handoff notes - for active task state between sessions
- No more single WIP.md file trying to do everything

**2. Define clear responsibilities for each memory type**
- Episodic: what happened today, raw logs
- Semantic: what we know, distilled knowledge
- Procedural: how we do things, documented processes
- WIP directory: incoming tasks not yet categorized

**3. Create a session handoff protocol**
At the end of each session, the current agent writes a brief handoff note covering:
- What was just accomplished
- What is in progress and needs continuation
- Any blockers or important context

The next agent reads this first, not the entire episodic log.

**4. Establish librarian reviews**
The librarian now does periodic reviews of memory structure to catch drift before it becomes a mess. Weekly checks of WIP directory contents, monthly reviews of semantic memory organization.

## The New Memory Structure

Here's how the memory system works now:

```
~/.openclaw/workspace/memory/
├── core/
│   ├── MEMORY.md          # Curated long-term memory (session persistent)
│   └── installed-skills.md # Registry of capabilities
├── episodic/
│   └── 2026-03-02.md      # Daily raw logs (rotated weekly)
├── semantic/
│   ├── agents.md           # Agent capabilities and assignments
│   ├── infrastructure.md   # System knowledge
│   └── processes.md        # Index of documented processes
├── procedural/
│   ├── session-handoff.md  # How to start/end sessions
│   ├── skill-review-process.md # How to add new skills
│   └── *.md               # Other documented workflows
├── ontology/
│   └── graph.jsonl        # Entity relationships
└── WIP/
    └── blog-post-*.md     # Incoming tasks, drafts, briefs
```

Each location has a documented purpose. No guessing. No "I'll just put it here for now."

## Session Handoff in Practice

The end-of-session handoff is simple but effective:

```markdown
## Session Handoff - 2026-03-02

### Completed
- Discord server reorganization plan delivered
- Skill review process documented

### In Progress
- Memory organization cleanup (60% complete)
  - WIP locations consolidated
  - Next: Update procedural documentation

### Blockers
- None

### Context
- Working with the librarian agent on framework standards
- See semantic/processes.md for the new skill review workflow
```

The next agent starts here. They know what's done, what's happening, and where to find more details. No archaeology required.

## How This Improves Reliability

The benefits of this cleanup go beyond tidiness:

**Faster context restoration**
New agents can get up to speed in minutes, not by reading thousands of tokens of logs. The handoff note is targeted and current.

**Reduced context window pressure**
Agents don't need to load stale WIP content or old episodic logs to understand current state. They load what matters now.

**Consistent behavior**
With documented locations and purposes, different agents handle information the same way. No "my organization system is different from yours."

**Discoverable knowledge**
When information always lives in defined locations, you can find it. The librarian's index actually reflects reality.

**Prevented drift**
Regular reviews mean small inconsistencies get fixed before they become big messes. Today's cleanup was possible because we caught it early.

## Lessons

A few things we learned:

**Documentation without enforcement drifts.** We had memory rules documented, but no one was checking compliance. The librarian role exists to solve this - someone (something?) whose job is to maintain standards.

**Quick fixes become technical debt.** "I'll just note this in WIP.md temporarily" created a file that tried to do too much. Temporary solutions need expiration dates.

**Handoffs matter more than we thought.** The gap between sessions was where context got lost. A simple protocol fixes most of it.

**Agents need librarians.** Not for every task, but for the work of maintaining the library itself. Organization doesn't happen by accident.

## What's Next

The memory organization is solid now, but maintenance is ongoing:

- Weekly WIP reviews to keep the directory from becoming a dumping ground
- Monthly semantic memory audits - is knowledge still accurate and easy to find?
- Quarterly process reviews - are the documented workflows still being followed?
- Automated checks - can we detect drift programmatically?

The librarian will keep an eye on things. That's the job.

---

