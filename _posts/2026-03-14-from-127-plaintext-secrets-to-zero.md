---
layout: single
classes: wide
title: "From 127 Plaintext Secrets to Zero: Our 1Password Migration"
date: 2026-03-14
header:
  teaser: /assets/img/1password-migration.jpg
author: derek
tags: [openclaw, security, 1password, credentials, homelab]
---
Running an AI agent system means managing a lot of API keys. Anthropic, OpenRouter, Cloudflare, Google, Discord, Brave Search, Todoist, Notion — the list grows with every integration. For months, those credentials lived in `.env` files and JSON configs. It worked. It also meant plaintext secrets scattered across dozens of files.

Today we fixed that.

## The Starting Point

Our OpenClaw setup had **127 plaintext credentials** spread across:

- `openclaw.json` (main gateway config)
- 11 agent `models.json` files (each with their own provider apiKeys)
- Agent `auth-profiles.json` files
- Skill configurations

Every agent needed access to the same providers — Anthropic for Claude, OpenRouter for routing, Cloudflare AI Gateway, Ollama for local models. That meant the same API keys duplicated 11 times across agent configs.

The `openclaw secrets audit` command made the problem impossible to ignore:

```
Secrets audit: findings. plaintext=127, unresolved=0
```

127 plaintext secrets. Time to do something about it.

## Why 1Password

We considered several approaches:

- **Environment variables only** — Better than hardcoded values, but still plaintext on disk in `.env` files
- **HashiCorp Vault** — Powerful, but overkill for a homelab. We'd tried it before and the operational overhead wasn't worth it
- **1Password CLI** — Already using 1Password for personal credentials. Service account tokens enable non-interactive access. OpenClaw has native SecretRef support for exec-based secret providers

1Password won because it met every requirement without adding infrastructure. No new services to maintain, no new failure modes. Just `op read` pulling secrets at runtime.

## The Migration Strategy

We approached this deliberately. "Test small" was the guiding principle — validate one credential end-to-end before touching anything else.

### Phase 1: Foundation

Set up 1Password CLI with a service account token and created an `OpenClaw-API-Keys` vault. Each credential became a vault item:

```
ANTHROPIC_API_KEY
OPENROUTER_API_KEY  
CLOUDFLARE_AI_GATEWAY
DISCORD_TOKEN
BRAVE_SEARCH_API_KEY
GEMINI_API_KEY
SYNTHETIC_API_KEY
... (40+ items total)
```

OpenClaw's `secrets.providers` config maps each item to an exec provider:

```json
"onepassword_anthropic": {
  "source": "exec",
  "command": "/usr/bin/op",
  "args": ["read", "op://OpenClaw-API-Keys/ANTHROPIC_API_KEY/password"],
  "passEnv": ["HOME", "OP_SERVICE_ACCOUNT_TOKEN"],
  "allowInsecurePath": true
}
```

### Phase 2: Skills First (Low Risk)

We started with skill-level credentials — Todoist, Notion, GoPlaces, Pulse. These are isolated integrations. If one breaks, the agent loses a capability but keeps running.

Each skill config changed from:

```json
"apiKey": "sk-actual-secret-value"
```

To a SecretRef:

```json
"apiKey": {
  "source": "exec",
  "provider": "onepassword_todoist",
  "id": "value"
}
```

Gateway restart. Skills still worked. Confidence building.

### Phase 3: Auth Profiles (Bulk Migration)

Agent auth-profiles were the biggest win. We had 8 agents × 6 provider profiles = 48 credential references. Rather than updating each individually, we built the auth-profiles template on the `main` agent and propagated it to all others.

The auth-profile pattern:

```json
{
  "openrouter:default": {
    "type": "api_key",
    "provider": "openrouter",
    "keyRef": {
      "source": "exec",
      "provider": "onepassword_openrouter",
      "id": "value"
    }
  }
}
```

Each agent's `models.json` apiKey changed from the actual secret to `"secretref-managed"` — a marker that tells OpenClaw to resolve credentials through the auth-profile system instead.

### Phase 4: Provider Consolidation

While migrating credentials, we discovered we had three separate Ollama providers (`ollama`, `ollama-cloud`, `ollama-remote`) that could be consolidated into one. The native Ollama API now handles both local and cloud models through a single provider with cloud models using the `:cloud` suffix.

This wasn't strictly a security task, but it eliminated 20+ redundant model references and simplified the config significantly.

### Phase 5: The Hard Ones

Two credentials needed special handling:

**Discord token** — First attempt at a SecretRef failed on gateway restart. The token is needed early in the boot sequence, and timing with the 1Password CLI caused issues. Second attempt after other providers were working succeeded. Lesson: test critical path credentials carefully.

**Brave Search API key** — The 1Password item used a `credential` field instead of the standard `password` field. Required pointing the `op read` path at the correct field name. Also needed `allowInsecurePath: true` because `/usr/bin/op` is owned by root, not the current user.

**Gemini API key** — The onboard wizard set a SecretRef id of `"google/apiKey"` which made OpenClaw try to parse the raw `op read` output as JSON and traverse a path. Changed to `"value"` to match how all other `op read` providers work with raw text output.

### Phase 6: Cleanup

The final 13 "plaintext" items were placeholder strings (`"whisper-remote"`, `"OLLAMA_API_KEY"`) on local services that don't require authentication. Removing the `apiKey` field entirely from those providers cleared the audit completely.

## The Result

```
Before: plaintext=127, unresolved=0
After:  plaintext=0,   unresolved=0
```

Every real secret now resolves at runtime through 1Password. Nothing sensitive lives in config files. The `openclaw.json` can be committed to git without worry.

## Lessons Learned

**Test small, then scale.** Starting with low-risk skill credentials built confidence before touching auth-profiles and the Discord token.

**Backup before every change.** We created timestamped backups before each phase. When the Discord token SecretRef failed on first attempt, reverting was trivial.

**Watch for field name mismatches.** Not every 1Password item uses `password` as the field name. Some use `credential`, `token`, or custom fields. The `op read` path needs to match exactly.

**`allowInsecurePath` matters.** The 1Password CLI binary is owned by root. OpenClaw's exec provider security check will reject it unless you explicitly allow insecure paths.

**Consolidate while you're in there.** The provider cleanup happened naturally alongside the credential migration. If you're already touching every config file, it's the right time to simplify.

**The `secrets audit` command is your friend.** Running it after every change gave immediate feedback. No guessing about what's left.

## What's Next

The `.env` file still exists with the `OP_SERVICE_ACCOUNT_TOKEN` — the one secret that bootstraps access to all others. That's an acceptable tradeoff. You need one root of trust somewhere, and a file with restricted permissions on a single machine is reasonable for a homelab.

The operational pattern is established now. Any new integration gets a 1Password vault item and a SecretRef provider. No more plaintext.

---

*This post documents real infrastructure work on our OpenClaw homelab. The migration took approximately one focused session. Your setup may vary depending on provider count and agent configuration.*
