---
layout: post
title: "Building the OpenClaw Journal"
date: 2026-02-18
image: "/assets/img/journal.jpg"
author: derek
tags: [homelab, openclaw, nextjs, payload-cms, blog]
---
I've been running a homelab for a while now, and I've been working with AI agents - specifically Claude via OpenClaw - to manage infrastructure, automate workflows, and generally push the boundaries of what a solo operator can pull off. But I never had a place to write about it. That changes today. 

This is the story of how the OpenClaw Journal came to be, from an empty GitHub repo to a fully scaffolded blog running Next.js 14 and Payload CMS 3.

## Why Build a Blog at All?

Honestly, I kept hitting the same problem: I'd solve something interesting in the homelab, learn a hard lesson about agent coordination, or discover a workflow that saved me hours - and then it would just... disappear into chat history. No documentation. No way to share it with anyone else running a similar setup.

I wanted something like [selfh.st](https://selfh.st/) or [technotim.com](https://www.technotim.live/) - dark theme, clean typography, technical content that respects the reader's time. But I also wanted it self-hosted on my own infrastructure. Eating my own dogfood, as they say.

## Setting Up the Repo

The project lives at [github.com/derekleeds/openclaw-journal](https://github.com/derekleeds/openclaw-journal). Getting the repo created was actually one of our first challenges (more on that in a later post), but once it was up, the scaffolding went fast.

The initial commit was just the project plan as a README - laying out the architecture, the tech stack, and the goals. From there, OpenClaw took over the heavy lifting.

## The Stack

Here's what we're running:

- **Next.js 14** with the App Router for the frontend
- **Payload CMS 3** for content management - it runs inside the same Next.js app, which is clean
- **MongoDB** for the database backend
- **Tailwind CSS** + **shadcn/ui** for styling
- **Coolify** for deployment on the homelab

I chose Payload CMS 3 because it's TypeScript-native, integrates directly into Next.js, and gives me a proper admin panel without needing a separate service. The Lexical rich text editor is solid, and having draft mode with autosave means I can write posts without worrying about losing work.

## Designing the UI

This is where it got fun. I wanted a design language that felt technical but approachable. Dark theme by default (of course), with components that could be reused across the site.

We built several custom components:

- **PostCard** - the card layout for the posts archive, showing title, excerpt, date, and tags
- **AuthorBadge** - a compact author display with avatar and name 
- **TagChip** - styled tag pills for categorizing posts
- **ThemeToggle** - because even though dark mode is the default, some people need their light mode

The whole design system is built on Tailwind with shadcn/ui primitives underneath. It's the fastest way I've found to build consistent, accessible UIs without fighting a component library.

## Installing the Skills

One of the more interesting parts of this build was the skills ecosystem. OpenClaw uses installable skills - specialized knowledge packs that give the agent deep expertise in specific tools and frameworks. For this project, we loaded up:

- `nextjs-best-practices` - App Router patterns, server components, data fetching
- `payload` - Payload CMS 3 collections, hooks, access control
- `tailwind-design-system` - utility-first CSS, responsive design, dark mode
- `shadcn-ui` - component patterns, theming, customization
- `frontend-design` - layout, typography, color theory

Having these skills active meant the agent could scaffold the entire project with correct patterns from the start - no cargo-culting from outdated tutorials, no fighting with deprecated APIs.

## Current Status

As I write this, the site is scaffolded and the code is pushed to GitHub. The next step is deploying to Coolify on the homelab. The Coolify API integration turned out to be trickier than expected (again, more on that later), but we're close.

The Posts collection is configured with:
- Rich text content via Lexical editor
- Hero images with responsive sizing
- Author relationships
- Category and tag support
- Draft mode with scheduled publishing
- SEO metadata via the Payload SEO plugin

It's a solid foundation. Now we just need to fill it with content - starting with this post.

## What's Next

- Deploy to Coolify on the homelab cluster
- Set up the custom domain at `openclaw.derekleeds.cloud`
- Write more posts documenting the homelab journey
- Add RSS feed support
- Maybe add search if the content volume justifies it

If you're building something similar - a self-hosted technical blog on your own infrastructure - I hope this gives you a useful starting point. The combination of Next.js + Payload CMS + Coolify is genuinely great for this use case.

More to come.
