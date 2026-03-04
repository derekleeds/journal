---
layout: single
title: "Migrating My Homelab to Talos Linux: Part 1 - The Kexec Plan"
date: 2026-03-04
author: derek
classes: wide
header:
  teaser: /assets/img/server-tech.jpg
  image: "/assets/img/server-tech.jpg"
tags: [talos, kubernetes, homelab, migration, kexec, proxmox]
---
I've been running my homelab Kubernetes clusters on Proxmox VMs for a while now. It works, but there's always been this nagging feeling: I'm managing general-purpose operating systems when all I really want is Kubernetes. Every security update, every package manager conflict, every "wait, why is this service running?" moment could be eliminated with something purpose-built.

Enter **Talos Linux** - a Kubernetes-native operating system that strips away everything that isn't Kubernetes. No SSH, no package manager, no shell. Just an API-driven, immutable infrastructure platform designed from the ground up for running containers.

This is the story of migrating my homelab from Proxmox VMs to Talos Linux, and how a clever trick called "kexec" was supposed to make it all happen remotely - without ever touching a USB drive.

## Why Talos?

Before we dive into the migration, let's talk about why Talos is interesting for homelab operators:

**1. Purpose-Built for Kubernetes** - Talos isn't a general-purpose Linux distro with Kubernetes bolted on. It's designed from the kernel up to run Kubernetes workloads. This means fewer moving parts, smaller attack surface, and less operational overhead.

**2. Immutable Infrastructure** - The OS is read-only. Configuration happens through a machine config file, applied via the Talos API. No more configuration drift between nodes.

**3. API-Driven Everything** - Want to upgrade the OS? Apply a new config? Check node health? All done via API calls. No SSH required (there literally isn't a shell).

**4. Atomic Updates** - Upgrades are A/B partition swaps. If something goes wrong, the previous partition is still there and can be rolled back automatically.

For my homelab, this translates to less time maintaining nodes and more time running workloads. Perfect.

## The Kexec Plan

Here's where it gets interesting. Talos typically requires reinstalling nodes from boot media - USB drive, ISO mounted over IPMI, or PXE boot. My HP EliteDesk 800 G3 mini desktops don't have IPMI, and PXE boot on my network would require infrastructure changes I wasn't ready to make.

But there's a lesser-known path: **kexec**.

Kexec is a Linux syscall that lets you load a new kernel from a running system, bypassing the BIOS boot process. You're essentially "hot-swapping" the kernel and rebooting directly into it. This is incredibly useful for Talos migration because:

1. Download Talos kernel and initramfs to your existing VM
2. Configure kexec to boot into Talos
3. The Talos installer takes over and wipes the disk
4. Fresh Talos installation, no USB required

This means I could migrate all three nodes remotely from my desk, without ever walking over to physically plug in a drive.

## Progress So Far

The plan was solid. Here's what we accomplished:

### Phase 1: Research ✅
Confirmed the kexec approach works. Talos documentation covers this, and some brave souls in the community have successfully migrated this way. The process isn't officially supported, but it's well-documented.

### Phase 2: Network Migration ✅
My nodes were on the 192.168.x.x network. Talos would need static IPs on my dedicated Kubernetes VLAN (VLAN 10, 10.10.10.0/24). Migrated all three nodes:
- cluster003-node1: 10.10.10.11
- cluster003-node2: 10.10.10.12
- cluster003-node3: 10.10.10.13

### Talos Assets Prepared ✅
Downloaded Talos v1.12.4 kernel (`vmlinuz`) and initramfs (`initramfs.xz`) to each node. The kexec command would load these and boot directly into the Talos installer.

### Cluster Config Generated ✅
Created the cluster configuration files - `controlplane.yaml` for the first node (which becomes the control plane) and `worker.yaml` for joining additional nodes. All three nodes will run both control-plane and worker workloads for a compact, highly-available setup.

### IaaC Structure Created ✅
Set up the homelab Infrastructure-as-Code repository with directories for Kubernetes manifests (`kubernetes/`), Docker Compose stacks (`docker-compose/`), and Talos configurations (`talos/`). Future updates will be tracked and versioned.

## The Blocker: Secure Boot

And then we hit a wall.

When I tried to execute kexec on the first node, I got:
```
kexec_file_load: Operation not permitted
kexec_load: Operation not permitted
```

Both kexec syscalls are blocked by **kernel lockdown mode**. This is a security feature, and it's enforced because **Secure Boot is enabled** in the BIOS.

Here's the chain of causation:
1. Secure Boot verifies kernel signatures at boot
2. Enabling Secure Boot puts the kernel into "lockdown" mode
3. Lockdown mode disables certain "dangerous" syscalls
4. kexec (loading arbitrary kernels) is considered dangerous
5. Therefore: kexec is blocked

This makes sense from a security perspective - Secure Boot exists to ensure only trusted kernels run. If you could kexec any kernel, you'd bypass that trust chain.

Why didn't I think of this earlier? Proxmox doesn't typically enable Secure Boot on VMs, so it wasn't on my radar. These machines were former corporate desktops, and Secure Boot was enabled in their original configuration.

## What's Next

The fix is simple but requires physical presence: disable Secure Boot in the BIOS on each node.

When I'm next on-premises:
1. Boot each node and press F10 to enter BIOS
2. Navigate to Secure Boot settings
3. Disable Secure Boot
4. Save and reboot

Once Secure Boot is disabled, the kernel exits lockdown mode, and kexec becomes available again. The migration can proceed remotely.

## The Hardware

For those curious about the setup:

- **3x HP EliteDesk 800 G3 Desktop Mini**
- **CPU:** Intel Core i5-6500T (4 cores, 2.5GHz base, 3.1GHz turbo)
- **RAM:** 16GB DDR4 per node
- **Storage:** NVMe SSD
- **Network:** Gigabit Ethernet, Tailscale overlay for remote access

These are compact, power-efficient machines (65W TDP) that I picked up used. Perfect for a homelab cluster. All three will run both control-plane and worker workloads in a highly-available configuration.

## Why This Still Matters

Even with the Secure Boot blocker, this migration approach is valuable:

1. **Learned Something** - Kernel lockdown and kexec security models are now in my mental toolbox
2. **Kexec is Scriptable** - Once Secure Boot is off, the entire migration can be scripted for future use
3. **Remote-First Design** - Everything else is prepared; after one physical visit, the rest is API calls

## Remaining Phases

Once Secure Boot is resolved:
- **Phase 3:** Talos Installation via kexec
- **Phase 4:** Cluster Initialization (talosctl bootstrap)
- **Phase 5:** Infrastructure-as-Code documentation
- **Phase 6:** Test workloads (nginx, cert-manager, etc.)
- **Phase 7-8:** Service migration from existing clusters

## Conclusion

The kexec migration plan isn't dead - it's just paused until I can physically visit the nodes. This is the reality of homelab administration: sometimes the "smart" remote solution hits a hardware configuration you didn't account for.

But here's the thing: I still think kexec is the right approach. It's scriptable, repeatable, and doesn't require me to burn USB drives for every installation. Secure Boot was a reasonable security feature for these machines in their previous life. It just happens to conflict with this particular migration method.

In Part 2, I'll cover the actual Talos installation and cluster initialization - once I've made that trip to disable Secure Boot. Stay tuned.

---

*The cluster003 migration is documented in my homelab infrastructure repository. Follow along for updates.*