---
title: "Challenges & How We Overcame Them"
date: 2026-02-18
author: derek
tags: [openclaw, homelab, troubleshooting, lessons-learned]
category: openclaw
---

# Challenges & How We Overcame Them

Nothing in the homelab works on the first try. That's not a complaint - it's just reality. Every project comes with its own set of obstacles, and the OpenClaw Journal was no exception.

Here's an honest accounting of what went wrong and how we fixed it. If you're building something similar, maybe this saves you a few hours of debugging. 

## GitHub CLI Repo Creation Failed

**The problem:** When we tried to create the openclaw-journal repository using `gh repo create`, it failed. Authentication issues, permission errors - the usual suspects when automating GitHub operations from a non-interactive environment.

**How we fixed it:** Manual creation. Sometimes the fastest path through a wall is around it. I created the repo manually through the GitHub web interface, then had the agent clone it and push the scaffolded code. Total time lost: maybe 10 minutes.

**The lesson:** Don't over-automate the one-time setup tasks. Creating a GitHub repo is something you do once per project. Spending 30 minutes debugging API auth for a task that takes 30 seconds manually is a bad trade.

That said, we did eventually sort out the GitHub CLI auth for future use. The issue was a token scope problem - the token didn't have the `repo` scope needed for repository creation. Adding the right scopes to the personal access token fixed it for subsequent projects.

## Coolify API Access Blocked

**The problem:** We wanted to deploy the blog to Coolify programmatically - configure the project, set environment variables, trigger the build. But the Coolify API wasn't responding. Requests were timing out or returning 403 errors.

**How we fixed it:** Two things needed to happen:

1. **Enable the API**: Coolify's API isn't enabled by default. You need to go into the Coolify settings and explicitly turn it on. This is a security-conscious default, but it's easy to miss if you're jumping straight to API integration.

2. **Generate an admin API token**: Even with the API enabled, you need a valid authentication token. Coolify uses API tokens tied to user accounts. We generated one through the Coolify admin panel under Settings → API Tokens.

Once both pieces were in place, the API worked as documented. The OpenClaw skill for Coolify now includes these setup steps so we don't hit this again.

**The lesson:** When an API isn't working, check the basics first. Is it enabled? Is your auth valid? Is the endpoint correct? It's rarely a deep technical issue - it's usually configuration.

## Claude Code Rate Limits Hit

**The problem:** During heavy development sessions - especially when scaffolding a full project with multiple files, components, and configurations - we hit Claude Code's rate limits. The agent would be mid-task and suddenly get throttled.

**How we fixed it:** Waited for the rate limit to reset. There's no clever workaround here. Rate limits exist for a reason, and trying to circumvent them is a losing strategy.

What we did improve was our approach to avoid hitting limits as often:

- **Batch related changes**: Instead of making many small edits, we'd plan the changes and make them in larger, more efficient operations
- **Use the right model**: Not every sub-task needs Opus. Using Haiku for exploration and simple lookups, Sonnet for standard development, and reserving Opus for complex work reduces the load significantly
- **Parallelize with sub-agents**: When multiple independent tasks need to happen, dispatch them to sub-agents running concurrently rather than doing everything sequentially in one context

**The lesson:** Rate limits are a resource constraint, not a bug. Plan your work to use resources efficiently. The best way to deal with rate limits is to not hit them in the first place.

## Browser Tool Unavailable

**The problem:** Some tasks required fetching information from web pages - documentation, API references, configuration examples. The browser automation tool wasn't available in our environment.

**How we fixed it:** Used `curl` and `web_fetch` instead. For most cases, we didn't actually need a full browser - we just needed the content from a URL. A simple HTTP request with content extraction was sufficient.

For pages that required JavaScript rendering, we worked around it by:

- Finding the raw data source (API endpoints, JSON feeds) instead of scraping the rendered page
- Using cached or local documentation when available
- Checking if the information existed in the agent's training data

**The lesson:** When your preferred tool isn't available, think about what you actually need. A browser renders HTML into pixels. If you just need the text content, you don't need a browser - you need an HTTP client and a parser. Match the tool to the actual requirement, not the assumed one.

## NetBox Integration

**The problem:** We wanted the agent to be able to query and update NetBox - our infrastructure source of truth - as part of automated workflows. But there was no built-in integration.

**How we fixed it:** Two approaches, depending on the use case:

1. **Custom OpenClaw skill**: We created a NetBox skill that encodes knowledge of the NetBox API - endpoints, data models, common queries, authentication patterns. When the agent loads this skill, it knows how to interact with NetBox using standard HTTP requests.

2. **MCP server option**: For deeper, more structured integration, we explored setting up NetBox as an MCP (Model Context Protocol) server. This gives the agent a standardized interface to NetBox rather than raw API calls, with better type safety and discoverability.

The skill approach was faster to set up and covers most use cases. The MCP server is the better long-term solution for teams that want tighter integration.

**The lesson:** When you need an integration that doesn't exist, you have options. A skill gives the agent knowledge about how to use a tool. An MCP server gives the agent a structured interface to the tool. Both work - choose based on how deep the integration needs to be.

## The Meta-Lesson

Every one of these challenges has the same underlying pattern: **something didn't work as expected, and we had to adapt**. That's not a failure of planning - that's just how building things works.

The difference between a project that ships and one that doesn't isn't the absence of problems. It's the ability to work through them systematically:

1. Identify what's actually broken (not what you assume is broken)
2. Check the simple explanations first
3. If the direct path is blocked, find an alternative
4. Document the solution so you don't hit it again
5. Move on

The homelab is a constant exercise in this pattern. Something breaks, you fix it, you learn something, you keep going. That's the whole game.
