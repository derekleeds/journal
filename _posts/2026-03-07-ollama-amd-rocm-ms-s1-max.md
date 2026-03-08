---
layout: single
classes: wide
title: "Running Ollama with AMD ROCm on the MS-S1-MAX: From vLLM Experiments to Production"
date: 2026-03-07
header:
  teaser: /assets/img/ollama-amd-rocm-teaser.png
  image: "/assets/img/ollama-amd-rocm-teaser.png"
author: derek
tags: [ollama, amd-rocm, llm, self-hosted, strix-halo, ms-s1-max]
---

A few weeks ago, I wrote about my experiments with vLLM on the MS-S1-MAX. The Strix Halo APU had just arrived, and I wanted to see how far I could push local LLM inference on 128GB of unified memory. vLLM worked - sort of - but the ROCm support felt brittle, and I kept hitting edge cases with model compatibility.

I kept thinking: there's got to be a better way to run local models without constantly wrestling with the stack. So I switched to Ollama. Here's how that went.

## The Setup

The hardware hasn't changed: same AMD Ryzen AI Max+ 395, same 128GB RAM, same Radeon iGPU. What changed was the software approach.

Instead of managing Python environments and wrestling with vLLM's ROCm builds, I pulled the official Ollama container with ROCm support:

```yaml
# /opt/stacks/ollama/docker-compose.yml
services:
  ollama:
    image: ollama/ollama:0.17.5-rocm
    container_name: ollama
    restart: unless-stopped
    environment:
      - HSA_OVERRIDE_GFX_VERSION=11.0.0
      - OLLAMA_MAX_LOADED_MODELS=4
      - OLLAMA_NUM_PARALLEL=4
    volumes:
      - /mnt/nfs/models:/root/.ollama
    devices:
      - /dev/kfd:/dev/kfd
      - /dev/dri:/dev/dri
    ports:
      - "11434:11434"
```

The key here is `HSA_OVERRIDE_GFX_VERSION=11.0.0` - without it, ROCm doesn't recognize the Strix Halo GPU properly. And I'm using NFS for model storage because these files are enormous and I don't want to fill up the local NVMe.

## What Actually Works

I tested two models that matter for my use case: OpenAI's GPT-OSS 20B and 120B parameter variants.

**GPT-OSS 20B at 128K context:**
- 42 tokens per second
- About 21GB of memory consumed
- Fast enough for interactive use

**GPT-OSS 120B at 128K context:**
- 25 tokens per second
- About 67GB of memory consumed
- Still usable, just slower

For context, these same models on CPU-only inference run at 5-10 tokens per second. The GPU acceleration isn't just nice to have - it's the difference between usable and painful.

Here's the interesting part about concurrency: I can run four 20B models simultaneously, or one 120B plus one or two 20B models. I settled on allocating 100GB for GPU use, which seems to be the sweet spot for my workload.

## Integration with OpenClaw

Ollama talks to OpenClaw through a provider I call "ollama-remote". The setup is straightforward - point it at the Tailscale address, and it just works. The models show up alongside my other providers, so I can route requests based on context size needs.

I also have auto-sync and auto-index configured for the QMD knowledge base. When new documents go into the system, they get chunked and indexed automatically. Running this on local hardware means I don't have to think about API costs or rate limits when I dump a 500-page PDF into the system.

## What Didn't Work

Not everything was smooth. Qwen 3.5 models have a thinking mode bug that drops them to 0.2-0.4 tokens per second, which makes them basically unusable. I spent an embarrassing amount of time troubleshooting before realizing it was a known issue with those specific model weights, not my setup.

The lesson there: when a model performs inexplicably badly, check if it's the model, not your configuration.

## Lessons Learned

**GPU acceleration is non-negotiable.** I tested CPU-only as a baseline and immediately understood why people pay cloud providers for GPU instances. 5-10 TPS versus 25-42 TPS isn't a small difference - it's the difference between a thought finishing now versus losing your train of thought while waiting.

**Memory management matters more than I expected.** The 128GB sounds like a lot until you're loading multiple models. I learned to monitor `rocm-smi` output and think about which models stay resident versus which get unloaded.

**Ollama's simplicity is worth the trade-offs.** vLLM can be faster in some benchmarks, but Ollama just works. I spend less time debugging and more time actually using the models. For a homelab setup that I maintain in my spare time, that's the right call.

**Concurrent workloads are actually achievable.** Being able to run four agents in parallel without them stepping on each other changes what's possible with local AI. I can have background indexing, interactive chat, and batch processing all happening at once.

## Current State

The MS-S1-MAX sits on my network accessible via Tailscale. It's isolated to a secure VLAN, runs only the Ollama container, and pulls models from TrueNAS over NFS. Docker handles the container lifecycle, and I can update with a simple `docker compose pull && docker compose up -d`.

The whole system draws reasonable power, stays quiet under load, and serves requests fast enough that I don't feel the need to reach for cloud APIs most days.

## What's Next

I'm curious about the newer model releases coming out this year. As context windows keep growing and parameter counts climb, I'm watching to see where the 128GB ceiling becomes a constraint. For now though, this setup handles everything I throw at it.

If you're running AMD hardware with ROCm support and want local LLMs without the headaches, Ollama is worth the switch from more complex inference engines. Sometimes the simpler tool is the right one.

---

*Got questions about the setup? The Docker compose and environment details are in the post. Happy to share more specifics if you're trying to get something similar running.*
