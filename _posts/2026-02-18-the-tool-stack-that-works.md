---
layout: single
title: "The Tool Stack That Works"
date: 2026-02-18
author: derek
tags: [homelab, tools, proxmox, coolify, netbox, unifi, tailwind, shadcn]
show_date: true
read_time: true
share: true
related: true
---

# The Tool Stack That Works

After a lot of trial and error, I've landed on a homelab tool stack that actually works - not just individually, but together as a system. Each tool earns its place by solving a specific problem well and playing nicely with everything else.

Here's what I'm running and why. 

## Proxmox for Virtualization

Proxmox VE is the foundation of the whole lab. It gives me KVM-based virtual machines and LXC containers on bare metal, with a web UI that's genuinely good enough for daily management.

What makes Proxmox work for me:

- **Free and open source** - no licensing headaches, no feature-gated tiers
- **ZFS integration** - snapshots, replication, and data integrity built in
- **Clustering** - I can span workloads across multiple nodes when needed
- **API-driven** - everything I do in the UI, I can automate via the API

I run a mix of VMs and containers depending on the workload. Anything that needs kernel-level isolation or runs its own OS gets a VM. Lighter services run in LXC containers for better resource efficiency.

The Proxmox API is particularly important for the OpenClaw workflow. Being able to provision and manage VMs programmatically means the agent can spin up test environments, deploy services, and manage infrastructure without me clicking through a UI. 

## Coolify for App Hosting

Coolify is my deployment platform. Think of it as a self-hosted alternative to Vercel/Netlify/Railway. You point it at a Git repo, configure the build, and it handles the rest - builds, deployments, SSL, reverse proxy, the works.

For the OpenClaw Journal specifically, Coolify handles:

- Building the Next.js + Payload CMS app from the GitHub repo
- Managing the MongoDB database instance
- SSL termination via Let's Encrypt
- Environment variable management
- Zero-downtime deployments

The thing I like about Coolify is that it hits the right abstraction level. I don't want to manage Kubernetes for a blog. I don't want to write Dockerfiles and nginx configs for every project. Coolify gives me push-to-deploy without the complexity overhead.

That said, the Coolify API integration was one of our bigger challenges (covered in the next post). The API needs to be explicitly enabled, and getting the auth token sorted required some troubleshooting.

## NetBox for IPAM/DCIM

As the homelab grew, I needed a proper way to track what's running where. IP addresses, VLANs, physical hardware, virtual machines, network connections - it was all in my head or scattered across notes.

NetBox solves this. It's an infrastructure source of truth:

- **IPAM** - IP address management across all my subnets and VLANs
- **DCIM** - tracking physical hardware, rack layouts, and connections
- **Virtualization** - mapping VMs and containers to their hosts
- **Custom fields** - extending the data model for homelab-specific needs

I've also built a custom OpenClaw skill for NetBox integration, so the agent can query and update infrastructure data directly. When we provision a new service, the agent can check NetBox for available IPs, register the new device, and update the documentation - all in one flow.

There's also an MCP server option for deeper integration, which lets the agent interact with NetBox through a standardized protocol rather than raw API calls.

## UniFi for Networking

The network runs on Ubiquiti UniFi gear. I'm running a UniFi Dream Machine Pro as the gateway/controller with UniFi switches and access points throughout.

What UniFi gives me:

- **Centralized management** - one controller for all network devices
- **VLAN support** - proper network segmentation between trusted, IoT, guest, and lab networks
- **Traffic analytics** - visibility into what's talking to what
- **Reliable Wi-Fi** - the access points just work, which is more than I can say for some enterprise gear I've used

The VLANs are important for the homelab. I keep lab workloads isolated from the home network, IoT devices in their own segment, and management traffic on a dedicated VLAN. UniFi makes this straightforward to set up and maintain.

## Tailwind CSS + shadcn/ui for Styling

On the application side, I've standardized on Tailwind CSS with shadcn/ui for all frontend work. This isn't just for the blog - it's the default for any web UI I build.

**Tailwind** gives me:

- Utility-first CSS that's fast to write and easy to maintain
- Built-in dark mode support via the `dark:` variant
- Responsive design with mobile-first breakpoints
- No context switching between HTML and CSS files

**shadcn/ui** layers on top with:

- Pre-built, accessible components that I own (they live in my codebase, not in node_modules)
- Consistent design tokens via CSS variables
- Components built on Radix UI primitives for accessibility
- Easy customization - I can modify any component directly

The combination is fast. I can go from "I need a card component" to a fully styled, responsive, accessible card in minutes. For the OpenClaw Journal, we built PostCard, AuthorBadge, TagChip, and ThemeToggle components all on this foundation.

## OpenClaw Skills Ecosystem

This is the glue that ties everything together. OpenClaw skills are specialized knowledge packs that give the AI agent deep expertise in specific tools and frameworks.

For the homelab, I've built or installed skills for:

- **Proxmox management** - VM/container provisioning, snapshot management, cluster operations
- **Coolify deployment** - app configuration, environment management, deployment workflows
- **NetBox integration** - IPAM queries, device registration, infrastructure documentation
- **Next.js + Payload CMS** - application development with correct patterns
- **Tailwind + shadcn/ui** - UI development with the design system

The power of the skills ecosystem is that knowledge compounds. Once a skill is created, it's available for every future project. The agent doesn't need to re-learn how Coolify deployments work or how to query NetBox - it loads the skill and has that knowledge immediately.

## How It All Fits Together

The real value isn't in any single tool - it's in how they work together:

1. **Proxmox** provides the compute foundation
2. **UniFi** provides the network fabric with proper segmentation
3. **NetBox** tracks what's running where
4. **Coolify** deploys applications on top of the infrastructure
5. **Tailwind + shadcn/ui** provides the UI framework for web apps
6. **OpenClaw skills** let the AI agent orchestrate across all of these

When I want to deploy a new service, the workflow looks like: check NetBox for available resources → provision on Proxmox if needed → configure in Coolify → deploy from Git → update NetBox with the new service details. With the right skills loaded, the agent can handle most of this autonomously.

That's the stack. It's not the most exotic setup, but it works reliably and it scales with my needs. Sometimes boring infrastructure is the best infrastructure.
