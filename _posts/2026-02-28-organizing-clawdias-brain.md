---
layout: single
title: "Organizing Clawdia's Brain: How We Structured OpenClaw for Scale"
date: 2026-02-28
author: derek
tags: [openclaw, ai-agents, memory, organization, devops]
show_date: true
read_time: true
share: true
related: true
---

# Organizing Clawdia's Brain: How We Structured OpenClaw for Scale

*February 28, 2026*

If you've ever tried to keep an AI agent organized, you know the struggle. One day it's helping with devops, the next it's writing blog posts, and suddenly you realize it's trying to use your Notion API credentials to debug a Docker container. Context gets messy fast.

Today we spent a solid session organizing OpenClaw—"Clawdia"—to solve this problem. Here's what we did and why it matters.

## Why Organization Matters for AI Agents

AI agents aren't like traditional software. They don't have rigid function definitions or strict type systems. They work with *context*—and context is messy, expensive, and finite.

When an agent has access to every skill and every tool for every task, two things happen:

1. **Context bloat**: The agent wastes tokens loading irrelevant information
2. **Wrong tool for the job**: The email skill gets loaded when you're debugging Kubernetes

The solution? Give each agent a focused role with focused capabilities. Like hiring specialists instead of one person who's "good at everything."

## What We Organized

We tackled three main areas:

### 1. Skills
Skills are what Clawdia knows how to do. Before today, they lived scattered across the workspace. Now they have a proper home:

```
~/.openclaw/skills/           # Master skill directory (symlinks)
~/.openclaw/workspace/skills/ # Primary skill definitions
~/.openclaw/workspace-<agent>/skills/ # Agent-specific skills
```

Each skill is self-contained with a `SKILL.md` documenting:
- What it does
- Trigger phrases
- Required tools and permissions
- Usage examples

We have skills for everything: `docker-expert`, `kubernetes-specialist`, `proxmox-admin`, `home-assistant`, `vault-secrets`, `memory-manager`, and more. About 30+ skills total, symlinked to where they're needed.

### 2. Tools
Tools are the executable scripts and binaries that provide actual functionality. We centralized them:

```
~/.openclaw/bin/
└── vault-resolver    # HashiCorp Vault credential resolver
```

This is where custom scripts live. The `vault-resolver` is particularly cool—it lets skills fetch secrets from Vault without hardcoding credentials.

### 3. Documentation
The memory system got a major restructuring:

```
~/.openclaw/workspace/memory/
├── core/           # Identity, installed skills (permanent)
├── episodic/       # Daily session logs (YYYY-MM-DD.md)
├── semantic/       # Topic-based knowledge (infrastructure.md)
├── procedural/     # Workflows and guides (how-to docs)
├── ontology/       # Entity relationship graph
└── snapshots/      # Session backups
```

The `MEMORY-RULES.md` file enforces this structure. No more random files floating in the base directory.

## The New Structure: Agents with Focus

Here's where it gets interesting. Instead of one monolithic agent, we now have specialized sub-agents:

| Agent | Role | Skills |
|-------|------|--------|
| **code-crafter** | Building features, writing code | `coding-agent`, `frontend-design`, `docker-expert`, `devops-engineer`, `github`, `kubernetes-specialist` |
| **communicator** | Messaging, emails, coordination | `humanizer`, `todoist`, `gog`, `agentmail` |
| **homelab-maintainer** | Infrastructure management | `devops-engineer`, `docker-expert`, `proxmox-admin`, `beszel`, `home-assistant`, `ssh` |
| **monitor** | System health monitoring | `beszel`, `homelab-dashboard` |
| **orchestrator** | Multi-agent coordination | `agent-team-orchestration`, `todoist` |
| **researcher** | Information gathering | `tavily`, `find-skills` |
| **trace-debugger** | Debugging and troubleshooting | `systematic-debugging`, `docker-expert` |

Each agent has a `SOUL.md` file that defines its purpose, and only loads the skills it needs. The `code-crafter` agent doesn't know about your email templates. The `communicator` agent doesn't load Kubernetes manifests.

## Model Recommendations for Each Agent

Different tasks need different capabilities. Here's our model strategy:

### For Code-Crafter
```
Primary: anthropic/claude-sonnet-4-5
Fallback: openrouter/minimax/minimax-m2.5
```

Code needs precision and reasoning. Claude Sonnet excels at understanding complex codebases and generating clean, documented code.

### For Orchestrator
```
Primary: Deep reasoning models (Qwen3 235B Thinking, Kimi K2.5)
```

Orchestrating multiple agents requires planning and coordination—the kind of metacognition that reasoning models handle well.

### For Researcher
```
Primary: Fast, capable models (DeepSeek V3.1, GLM-4.7)
```

Research is often parallelizable and doesn't need the most expensive model. We use efficient models that can process large amounts of text quickly.

### For Monitor
```
Primary: Lightweight models (Llama 3.3 70B)
```

Monitoring is routine work. No need for heavy reasoning—just reliable pattern matching and alerting.

### For Debugging (trace-debugger)
```
Primary: Reasoning models (DeepSeek R1, Kimi K2 Thinking)
```

Debugging requires systematic deduction. Reasoning models excel at tracing through complex failure scenarios.

## How This Improves Context Preservation

The biggest win is *selective loading*. Here's the math:

**Before organization:**
- Loading all skills for every task: ~50,000 tokens
- Plus documentation references
- Plus tool configurations
- Agent context window: 20% consumed before conversation starts

**After organization:**
- Code-crafter loads 6 relevant skills: ~8,000 tokens
- Only procedural docs for current workflow
- Context window: 5% consumed at startup

That's more room for your actual conversation. More room for the agent to "think."

### Memory Hierarchy

We also implemented a three-tier memory system:

1. **Episodic** (daily logs): What happened today
2. **Semantic** (topic files): What we know about topics
3. **Procedural** (workflows): How to do things

The `memory-distill` skill automatically distills episodic memory into semantic knowledge weekly. This means:
- Daily logs capture everything
- Over time, patterns become permanent knowledge
- Old logs can be archived without losing insights

### Ontology Graph

We added an ontology layer in `memory/ontology/graph.jsonl` that tracks relationships:

```json
{"op":"create","entity":{"id":"proj_content_publishing","type":"Project"}}
{"op":"create","entity":{"id":"doc_content_proc_system","type":"Document"}}
{"op":"relate","from":"proj_content_publishing","rel":"has_doc","to":"doc_content_proc_system"}
```

This lets Clawdia understand that the Content Publishing project has documentation in both procedural and semantic memory. Knowledge graphs are the future of agent memory.

## A Tour Through Clawdia's Brain

Here's what the organized structure looks like in practice:

```
~/.openclaw/
├── agents/                 # Agent configurations
│   ├── main/
│   ├── code-crafter/
│   ├── communicator/
│   ├── homelab-maintainer/
│   ├── monitor/
│   ├── orchestrator/
│   ├── researcher/
│   └── trace-debugger/
├── skills/                 # Master skill directory (symlinks)
│   ├── devops-engineer -> ../.agents/skills/devops-engineer
│   ├── docker-expert -> ../.agents/skills/docker-expert
│   ├── kubernetes-specialist -> ...
│   └── ...
├── bin/                    # Tools
│   └── vault-resolver
├── workspace/              # Main agent workspace
│   ├── memory/
│   │   ├── core/
│   │   ├── episodic/
│   │   ├── semantic/
│   │   ├── procedural/
│   │   └── ontology/
│   ├── skills/
│   └── scripts/
└── workspace-<agent>/      # Sub-agent workspaces
    ├── SOUL.md
    ├── AGENTS.md
    ├── skills/
    └── memory/
```

Each workspace is its own Git repository, so agents can work independently without stepping on each other.

## Lessons for DevOps Learners

If you're learning DevOps (like Derek), here's what this project teaches:

1. **Symlinks are powerful**: We use symlinks to share skills across agents while keeping one source of truth. Edit the source, all agents see the change.

2. **Configuration as code**: Every agent has a `SOUL.md` defining who they are. This is infrastructure-as-code thinking applied to AI agents.

3. **Separation of concerns**: The same principle that keeps your microservices independent keeps your agents focused. Single responsibility principle isn't just for classes.

4. **Documentation pays off**: The time spent documenting skills and memory rules pays back exponentially when context is preserved across sessions.

## What's Next

The organization is solid, but we're not done:

- **Automated skill discovery**: Building `find-skills` to help agents discover new capabilities
- **Cross-agent communication**: Better protocols for the orchestrator to coordinate teams
- **Memory compression**: Smarter distillation of episodic into semantic memory
- **Tool sandboxing**: More secure isolation for agent tools

Clawdia's brain is more organized than ever. And that means more capable, more reliable, and more helpful—without the context chaos.

---

*Want to see the full structure? Check out `~/.openclaw/workspace/memory/procedural/skills-organization.md` for the complete procedural guide.*
