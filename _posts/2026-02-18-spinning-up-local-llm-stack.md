---
layout: post
title: "Spinning Up a Local LLM Stack on the MS-S1 MAX"
date: 2026-02-18
image: "/assets/img/ai-brain.jpg"
author: derek
tags: [homelab, llm, ai, inference, ms-s1-max, vllm, self-hosted]
---


I've been sending a lot of prompts to cloud APIs lately - Claude, GPT-4, the usual suspects. They're great, but every time I fire off an internal automation task or have Clawdia process something routine, I'm burning API credits and sending data off-prem. That's been bugging me for a while.

So I set up a local LLM inference stack on the MS-S1 MAX in my homelab. Here's how it went.

## Why Run LLMs Locally?

There are four reasons I wanted local inference, and they're all pretty simple:

**Privacy.** Some of the prompts I send include infrastructure details, IP addresses, config snippets, internal documentation. I'd rather keep that on my own network than ship it to someone else's data center. Not because I think OpenAI is reading my Proxmox configs, but because good security hygiene means minimizing unnecessary data exposure.

**Cost.** OpenClaw and Clawdia generate a lot of API calls for internal tasks - summarizing logs, generating commit messages, processing automation outputs. These are high-volume, low-complexity tasks. Paying per-token for that kind of work adds up fast, and the quality bar is lower than what you'd need for creative or complex reasoning tasks.

**Latency.** For certain workloads - especially real-time automation hooks - the round trip to a cloud API adds noticeable delay. A local endpoint on the same network shaves that down significantly. 

**Control.** I want to pick the model, pick the quantization, swap models without changing providers, and not worry about rate limits or deprecation notices. If a model works for my use case, I can run it until I decide to change - nobody's going to sunset it on me.

## The Hardware: MS-S1 MAX

The MS-S1 MAX is a high-end mini PC that punches well above its weight for inference workloads. The key spec is RAM - it has enough to load reasonably large models entirely into memory, which is what you need for CPU-based inference at acceptable speeds.

It sits on **VLAN 10 (Secure)** in my homelab network, which is the isolated segment I use for anything that handles sensitive data or runs AI workloads. VLAN 10 is firewalled off from the main lab network and the home network - it can reach out to the internet for model downloads, but inbound access is restricted to specific services via Tailscale and internal routing rules.

The Tailscale address is `100.90.135.47`, which means I can hit it from anywhere on my tailnet without exposing it to the broader internet.

For model storage, I'm using an **NFS mount from TrueNAS** at `/mnt/truenas/models/`. This is important - LLM model files are huge (anywhere from 4GB to 30GB+ depending on the model and quantization), and I don't want to eat up the MS-S1 MAX's internal storage. The TrueNAS box has plenty of spinning rust for bulk storage, and NFS keeps things simple.

The mount is straightforward:

```bash
truenas.lan:/mnt/pool/models  /mnt/truenas/models  nfs  defaults,soft,timeo=150  0  0
```

## The Stack

I'm running **vLLM** as the inference server. vLLM is a high-throughput inference engine that supports the OpenAI-compatible API format out of the box, which means any tool or library that speaks the OpenAI protocol can talk to it with zero changes.

The setup is containerized with Docker:

```bash
docker run -d \
  --name vllm-server \
  --restart unless-stopped \
  -v /mnt/truenas/models:/models \
  -p 8080:8000 \
  -e VLLM_CPU_ONLY=1 \
  vllm/vllm-openai:latest \
  --model /models/deepseek-r1-distill-qwen-7b-q5_k_m.gguf \
  --served-model-name snappy-deepseek \
  --max-model-len 8192 \
  --host 0.0.0.0
```

A few things to note:

- `VLLM_CPU_ONLY=1` - the MS-S1 MAX doesn't have a dedicated GPU, so we're running pure CPU inference. This is slower than GPU inference, but for the 7B-class models I'm targeting, it's perfectly usable.
- The model is a **Q5_K_M quantized** version of DeepSeek-R1 Distill Qwen 7B - a solid balance between quality and resource usage.
- Port 8080 externally maps to vLLM's default 8000 internally.
- `--max-model-len 8192` keeps the KV cache from eating all the RAM. You can push this higher if you have headroom, but 8K context is plenty for the automation tasks I'm running.

### Health Check

Once it's up, a quick sanity check:

```bash
curl http://100.90.135.47:8080/health
```

And you can hit the models endpoint to confirm the served model:

```bash
curl http://100.90.135.47:8080/v1/models
```

### Testing Inference

A quick test to make sure it's actually generating:

```bash
curl http://100.90.135.47:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "snappy-deepseek",
    "messages": [{"role": "user", "content": "What is VLAN trunking?"}],
    "max_tokens": 200
  }'
```

First-token latency on CPU is around 2-4 seconds depending on prompt length, with generation running at roughly 8-15 tokens/sec. Not blazing fast, but for internal automation tasks it's more than adequate.

## Integration with OpenClaw

This is where it gets useful. The local inference endpoint is configured as a custom provider in OpenClaw's config:

```json
// openclaw.json (relevant section)
{
  "providers": {
    "vllm-local": {
      "type": "openai-compatible",
      "baseUrl": "http://100.90.135.47:8080/v1",
      "models": {
        "snappy-deepseek": {
          "contextWindow": 8192,
          "maxOutput": 2048,
          "costPerInputToken": 0,
          "costPerOutputToken": 0
        }
      }
    }
  }
}
```

The model ID `snappy-deepseek` is what OpenClaw uses when routing tasks. It's configured as the default for:

- Log summarization
- Commit message generation
- Routine text processing
- Internal documentation drafts

For complex reasoning, code generation, and anything that needs top-tier quality, tasks still route to Claude. But for the high-volume, lower-stakes tasks? The local model handles them just fine - and the cost is effectively zero after the hardware investment.

It also serves as a **fallback** when cloud API quotas are exhausted or when there's a connectivity issue. If Claude or GPT-4 aren't reachable, OpenClaw can gracefully degrade to the local endpoint rather than failing outright.

## Lessons Learned

### NFS Performance Matters for Model Loading

Loading a 5GB+ model file over NFS is not instant. On my gigabit network, initial model load takes 30-60 seconds depending on file size. This is fine - you load the model once and it stays in memory. But if the vLLM process restarts (OOM kill, Docker update, host reboot), you're waiting again.

Two things that helped:

1. Use `soft,timeo=150` in the NFS mount options so the process doesn't hang indefinitely if TrueNAS is temporarily unreachable.
2. Consider pre-staging hot models to local SSD if you need faster restart times. I haven't done this yet, but it's on the list.

### VLAN Isolation Is Worth the Complexity

Having the inference stack on VLAN 10 means even if there's a vulnerability in vLLM or the model does something unexpected, the blast radius is contained. VLAN 10 can't reach my home network, can't reach the IoT devices, and has limited access to the rest of the lab.

The downside is routing complexity. Services on other VLANs that need to hit the inference API have to go through the firewall, which means explicit rules for each consumer. Tailscale simplifies this a lot - anything on my tailnet can reach `100.90.135.47:8080` regardless of VLAN, which is the path most of my tools use.

### Memory Management Is the Whole Game

CPU inference lives and dies by available RAM. The model weights need to fit in memory, the KV cache needs room, and you still need headroom for the OS and the inference server itself. With a 7B Q5 model, I'm using roughly 6-8GB for the model plus 2-4GB for KV cache, which leaves comfortable headroom on the MS-S1 MAX.

If you try to load a model that's too large, vLLM will either OOM or start swapping, and performance falls off a cliff. Monitor with:

```bash
watch -n 5 'free -h && echo "---" && docker stats --no-stream vllm-server'
```

### Quantization Tradeoffs

I tested a few quantization levels:

- **Q8_0** - Barely fits in memory, but quality is very close to full precision. Overkill for automation tasks.
- **Q5_K_M** - The sweet spot. Noticeable quality drop on hard reasoning tasks, but perfectly fine for summarization, formatting, and routine generation. This is what I run.
- **Q4_K_M** - Smaller and faster, but the quality degradation starts to show on anything beyond simple tasks.

For my use case, Q5_K_M is the right answer. If you're doing more demanding tasks locally, go Q8 and make sure you have the RAM to back it up.

## What's Next

The local inference stack is running and integrated, but there's more to do:

- **More models.** I want to have a few different models available for different task types - a fast small model for simple tasks and a larger model for when quality matters more. vLLM supports serving multiple models, so this is mostly a RAM question.
- **Smarter routing.** Right now the model selection is fairly static in the OpenClaw config. I want to build routing logic that automatically picks local vs. cloud based on task complexity, current load, and API availability.
- **Monitoring.** I need proper metrics - requests per minute, latency percentiles, token throughput, error rates. Prometheus + Grafana is the obvious answer, and vLLM already exposes a metrics endpoint.

Running local inference isn't going to replace cloud APIs for complex work. But for the 60-70% of tasks that don't need frontier model quality? It's a genuine improvement - cheaper, faster, and more private. The MS-S1 MAX is doing exactly what I bought it for.
