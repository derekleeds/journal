---
layout: single
classes: wide
title: "Building a Power-Fail Recovery System for Homelab"
date: 2026-02-18
header:
  teaser: /assets/img/server-tech.jpg
  image: "/assets/img/server-tech.jpg"
author: derek
tags: [homelab, automation, unraid, home-assistant, n8n, ups]
---
I live in an area where the power goes out a few times a year. Not long outages usually - 30 minutes, maybe an hour - but long enough to matter when you're running a homelab that hosts real services.

My Unraid server sits behind an Eaton 5PX 1500 UPS, and the UPS does its job. When power drops, it keeps the server alive long enough to trigger a clean shutdown through the NUT (Network UPS Tools) integration. The array stops, the drives park, the machine powers off gracefully. That part works great.

The problem is what happens *after* the power comes back.

## The Problem: Everything Shuts Down, Nothing Comes Back

The Unraid box shuts down cleanly. That's the good news. The bad news is that when utility power is restored, the server just sits there. Powered off. Doing nothing. Every VM, every Docker container, every service - all offline until I physically walk over and press the power button, or remote in to deal with it.

If I'm home, it's a minor inconvenience. If I'm traveling or asleep, those services can be down for hours before I notice. And even after the machine boots, the Unraid array doesn't auto-start by default - so you're looking at a multi-step recovery process:

1. Power comes back
2. Someone (me) notices the server is down
3. I either press the button or wake it remotely
4. Machine boots into Unraid
5. I log in and manually start the array
6. Docker containers and VMs come back up

Steps 2 through 5 are manual. That's unacceptable for a lab that's supposed to run itself.

## The Solution: Home Assistant + n8n + Wake-on-LAN

The idea is straightforward: detect when power is restored, wake the server automatically, then start the Unraid array programmatically. Three stages, fully automated.

Here's the hardware and software involved:

- **Eaton 5PX 1500 UPS** - provides battery backup and reports status via NUT
- **Home Assistant** - running on a separate low-power device that boots automatically on power restore (this is important - your automation controller needs to survive the same outage)
- **n8n** - workflow automation engine for the array startup logic
- **HashiCorp Vault** - secret management for credentials
- **Wake-on-LAN** - the magic packet that tells the Unraid server's NIC to power on the machine

### Why Not Just Use BIOS "Restore on AC Power Loss"?

Good question. Most server motherboards have a BIOS setting to automatically power on when AC power is restored. I actually tried this first. Two problems:

1. **The UPS is still in the loop.** The server doesn't lose AC power when utility power drops - the UPS keeps it alive, and NUT triggers a *clean shutdown* before the battery runs out. So from the motherboard's perspective, it was shut down normally, not from a power loss. The BIOS "restore on AC" setting doesn't trigger because the machine doesn't see an AC loss event - it sees a normal shutdown.

2. **Even if it did work, it only solves the boot.** The Unraid array still wouldn't auto-start, and all the containers and VMs would still be sitting idle until someone starts the array.

So we need something smarter.

## Stage 1: Detecting Power Restoration

Home Assistant is the cornerstone here. It runs on a Raspberry Pi that's also on a UPS (a smaller one - it sips power, so even a basic UPS keeps it alive through extended outages). The Pi is configured in BIOS to power on when AC is restored, and it boots fast enough that HA is up and running within a couple minutes of power coming back.

The Eaton 5PX reports its status to HA via the NUT integration. The key sensor is `sensor.ups_status`:

- `OL` - Online (utility power present, running on mains)
- `OB` - On Battery (utility power lost, running on battery)
- `OL CHRG` - Online and charging (power just came back, battery recharging)

The automation triggers on the transition from `OB` to `OL` or `OL CHRG`. That's our signal that utility power has been restored.

```yaml
automation:
  - alias: "Power Restored - Wake Unraid"
    trigger:
      - platform: state
        entity_id: sensor.ups_status
        from: "OB"
        to: "OL"
      - platform: state
        entity_id: sensor.ups_status
        from: "OB"
        to: "OL CHRG"
    condition:
      - condition: state
        entity_id: binary_sensor.unraid_server
        state: "off"
    action:
      - delay:
          minutes: 2
      - service: wake_on_lan.send_magic_packet
        data:
          mac: "AA:BB:CC:DD:EE:FF"
          broadcast_address: "10.0.20.255"
```

A few things to note:

- The **2-minute delay** is intentional. I don't want to wake the server the instant power flickers back. If the power is unstable (comes back, drops again, comes back), that delay prevents the server from booting into a brownout situation. Two minutes is enough to confirm the power is genuinely stable.
- The **condition** checks that the Unraid server is actually off. If it's already running (maybe the outage was short enough that NUT didn't trigger a shutdown), there's nothing to do.
- The **broadcast address** targets the correct subnet. WOL packets need to reach the right network segment - if your server is on a different VLAN, make sure the broadcast goes to the right place.

## Stage 2: Wake-on-LAN

WOL itself is dead simple - it's a magic packet sent to the server's MAC address, and the NIC wakes the machine. But there are a couple prerequisites that tripped me up:

### Enable WOL in BIOS

This seems obvious, but it's buried in different places depending on your motherboard. On mine it was under **Advanced > APM Configuration > Power On By PCI-E**. It needs to be set to `Enabled`.

### Enable WOL in the OS

Unraid needs to have WOL enabled on the network interface. You can check and set this with `ethtool`:

```bash
ethtool enp2s0 | grep Wake-on

ethtool -s enp2s0 wol g
```

To make this persistent across reboots in Unraid, add it to the go file:

```bash
ethtool -s enp2s0 wol g
```

### The VLAN Gotcha

My Unraid server lives on **VLAN 20 (Lab)**. The Raspberry Pi running Home Assistant is on **VLAN 30 (Management)**. WOL magic packets are layer 2 broadcast frames - they don't route across VLANs by default.

I had two options:

1. **UDP directed broadcast** - send the WOL packet as a UDP broadcast to the target subnet. This requires the router/firewall to forward directed broadcasts, which most will do if you configure it.
2. **Put HA on the same VLAN** - simpler but defeats the purpose of network segmentation.

I went with option 1. The `broadcast_address` parameter in the HA WOL service handles this - set it to the broadcast address of the Unraid server's subnet, and configure your firewall to allow directed broadcasts from the management VLAN to the lab VLAN.

## Stage 3: Starting the Unraid Array with n8n

This is the part that took the most iteration. Once the server boots, Unraid comes up, but the array is stopped. Containers and VMs don't run until the array is started.

Unraid doesn't have a first-class API for array management. There's no `POST /api/array/start`. What it does have is a web UI that submits forms. So the approach is to programmatically submit the same form the UI does.

I use **n8n** for this because it handles the HTTP requests, timing, retries, and error handling cleanly. The workflow looks like this:

1. **Webhook trigger** - HA fires a webhook to n8n after sending the WOL packet and waiting for the server to boot (I add a 4-minute delay after WOL to give Unraid time to fully boot).
2. **Health check loop** - n8n polls the Unraid web UI until it gets a 200 response, confirming the server is up and the web interface is ready.
3. **Authenticate** - n8n logs into the Unraid web UI using credentials pulled from HashiCorp Vault.
4. **Start array** - n8n sends the POST request that starts the array, mimicking the form submission from the web UI.
5. **Verify** - n8n checks that the array actually started and Docker containers are coming up.

### Pulling Credentials from Vault

I'm not hardcoding the Unraid password in n8n. The credentials live in **HashiCorp Vault** under `secret/homelab/unraid`. n8n has a Vault integration that pulls secrets at runtime:

```json
{
  "path": "secret/data/homelab/unraid",
  "keys": {
    "username": "root",
    "password": "{{vault_secret}}"
  }
}
```

The Vault token used by n8n has a narrow policy - it can only read from the `secret/homelab/*` path. Principle of least privilege.

### The Array Start Request

After some browser dev tools spelunking, the request to start the Unraid array looks roughly like this:

```
POST /update.htm
Content-Type: application/x-www-form-urlencoded

startState=STARTED&cmdStart=Start
```

There's a CSRF token involved, so n8n first GETs the main page, extracts the token, then includes it in the POST. This was the most fragile part of the whole setup - any Unraid UI update could change the form structure or token handling.

### The Full n8n Flow

```
[HA Webhook] → [Wait for Unraid HTTP 200] → [Vault: Get Credentials]
    → [GET /Main - Extract CSRF] → [POST /update.htm - Start Array]
    → [Verify Array Started] → [Notify via Pushover]
```

If any step fails, n8n retries up to 3 times with exponential backoff. If it still fails after retries, I get a Pushover notification telling me what went wrong so I can intervene manually.

## What Didn't Work

### First Attempt: SSH + Script

My first approach was to have HA SSH into the Unraid box and run a script to start the array. This failed because Unraid's array management commands aren't straightforward CLI operations - there's no simple `unraid-array start` command. The array start process involves the web UI and its internal state management.

I could have reverse-engineered the internal scripts, but that felt brittle and likely to break on any Unraid update.

### CSRF Token Extraction Was Painful

The Unraid web UI doesn't make it easy to automate. The CSRF token is embedded in the page HTML, and the structure of the page has changed between Unraid versions. I went through three different regex patterns before landing on one that reliably extracts the token. Every time Unraid pushes an update, I hold my breath.

### Timing Is Tricky

Getting the delays right was trial and error. Too short and you're sending requests to a server that isn't ready. Too long and your services are down longer than necessary. The current values (2 minutes after power restore before WOL, 4 minutes after WOL before array start) work for my hardware, but they'd be different for a faster or slower machine.

I ended up adding the health check polling loop in n8n rather than relying on fixed delays. The fixed delay gets you in the ballpark, and the polling loop handles the variance.

## Lessons Learned

**Your automation controller must survive the outage.** If HA goes down with the server, nobody's left to start the recovery. A low-power device on its own UPS is essential.

**Layer 2 vs Layer 3 matters for WOL.** If your devices are on different VLANs, WOL doesn't just work. You need to think about how broadcast packets get from the sender to the target network. Directed broadcasts solve this but require firewall configuration.

**Don't hardcode credentials in automation workflows.** It's tempting to just paste the password into n8n and move on. Using Vault adds complexity, but it means you're not storing plaintext credentials in your workflow exports, backups, or version control.

**Test the whole chain, not just individual pieces.** WOL worked in isolation. The HA automation triggered correctly in isolation. The n8n workflow ran fine when triggered manually. But the first time I tested the full chain - kill power, wait for shutdown, restore power, watch it recover - the n8n workflow hit a race condition because the Unraid web UI takes longer to become responsive than I'd assumed. The polling loop fixed it, but I wouldn't have found the bug without an end-to-end test.

**Automating things that weren't designed to be automated is always fragile.** The weakest link in this whole chain is the Unraid array start. It's screen-scraping a web UI, extracting CSRF tokens, and submitting forms. It works today, but it's the first thing that'll break when Unraid changes their UI. If Unraid ever adds a proper API for array management, I'll switch to that immediately.

## What's Next

The system has been running for about two months now, and it's handled three real power outages without intervention. Each time, the full recovery - from power restoration to all containers running - took about 8-10 minutes. Not instant, but completely hands-off.

There are a few improvements on the list:

- **Staggered recovery for multiple servers.** Right now this only handles the Unraid box. If I add more servers to the lab, I'll need to sequence the wake order so I'm not slamming the UPS with all of them booting simultaneously.
- **Power quality monitoring.** I want to track outage frequency and duration over time. HA already has the data in its history - I just need to build a dashboard for it.
- **Graceful degradation notifications.** Right now I get notified on failure. I want proactive notifications for the whole sequence - "power lost," "power restored," "WOL sent," "array started," "all services up" - so I have full visibility even when everything works correctly.

If you're running a homelab and dealing with power outages, the biggest advice I can give is: don't just protect the shutdown path. Protect the recovery path too. The UPS handles the shutdown. But getting everything back up and running without human intervention - that's the harder problem, and the one worth solving.
