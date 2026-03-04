---
layout: single
classes: wide
title: "Lessons from the Trenches"
date: 2026-02-18
header:
  image: "/assets/img/learning.jpg"
author: derek
tags: [openclaw, ai-agents, lessons-learned, homelab]
---
I've spent a lot of time working with AI agents in the homelab - coordinating tasks, managing infrastructure, and building tools. Along the way, I've picked up some hard-won lessons that I wish someone had told me at the start.

This post is that document. The things I've learned about agent coordination, memory management, and knowing when to let the machine work versus when to step in yourself.

## Agent Coordination Patterns

The biggest shift in my thinking has been around how agents work together. Early on, I treated every task as a single-agent problem: give Claude a prompt, get a result, move on. That works for simple things. It falls apart fast when you're doing anything complex. 

What actually works is **task decomposition with specialized sub-agents**. The pattern looks like this:

1. A coordinator agent breaks the work into discrete tasks
2. Each task gets dispatched to a sub-agent with the right context and skills
3. Results flow back to the coordinator for synthesis

The key insight is that sub-agents should be **stateless and focused**. They get a clear task, they execute it, they return the result. They don't need to know about the broader project context - that's the coordinator's job.

## When to Use Sub-Agents vs. Manual Work

Not everything needs an agent. I've learned this the hard way by over-automating things that would have been faster to do by hand. Here's my rough heuristic:

**Use a sub-agent when:**
- The task is well-defined and repeatable
- It requires searching, reading, or synthesizing large amounts of information
- It involves code generation or transformation that benefits from specialized knowledge
- You need to do the same kind of work across multiple targets (files, services, configs)

**Do it manually when:**
- The task requires judgment calls that depend on broader context
- You're exploring and don't yet know what the right question is
- The setup cost of the prompt exceeds the work itself
- It's a one-off that'll never happen again

The sweet spot is somewhere in between - tasks that are complex enough to benefit from agent capabilities but well-defined enough that you can write a clear prompt.

## Memory Management and Continuity

This is the one that bit me the hardest. AI agents don't have persistent memory across sessions by default. Every new conversation starts from zero. If you're doing multi-session work - and you are, if you're building anything real - you need a strategy for continuity.

What I've found works:

- **Project files as memory**: Keep a `CLAUDE.md` or similar file in the repo root that captures project context, decisions made, and current status. The agent reads this at the start of every session.
- **Structured handoff notes**: When ending a session, have the agent write a summary of what was done, what's pending, and any blockers. This becomes the starting context for the next session.
- **Skills as institutional knowledge**: Instead of re-explaining tool configurations and patterns every time, encode them as installable skills. The agent loads the skill and immediately has deep knowledge of the tool.
- **Git history as the source of truth**: Commit messages, PR descriptions, and code changes form a durable record that survives across sessions. Write good commit messages.

The pattern I've settled on is: start each session by reading the project context files, check git status for the current state, then pick up where the last session left off.

## Model Selection: Opus vs. Sonnet vs. Haiku

Not every task needs the most powerful model. I've gotten better at matching the model to the work:

**Opus** is for the hard stuff:
- Complex architectural decisions
- Multi-file refactoring that requires understanding the whole codebase
- Writing nuanced content (like these blog posts)
- Debugging subtle issues where the root cause isn't obvious

**Sonnet** is the daily driver:
- Standard code generation and editing
- Implementing well-defined features
- Code review and analysis
- Most interactive development work

**Haiku** is for the quick hits:
- Simple searches and lookups
- File exploration and codebase navigation
- Straightforward transformations
- Tasks where speed matters more than depth

The cost difference is significant. Running Opus for everything is like driving a truck to get groceries - it'll work, but you're burning resources you don't need to. Match the model to the task, and your budget (and rate limits) will thank you.

## The Compound Effect

The real power isn't in any single agent interaction. It's in the compound effect of building up skills, patterns, and context over time. Each project teaches the next one. Each skill makes future work faster. Each solved problem becomes a template for the next.

Six months ago, scaffolding a full-stack blog with CMS, custom components, and deployment configuration would have been a multi-day effort. Today, with the right skills loaded and the right patterns established, it's an afternoon.

That's the real lesson from the trenches: invest in your tooling, document your patterns, and build systems that get smarter over time.
