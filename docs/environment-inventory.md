# Local LLM Environment Inventory

## Purpose

Capture the host and service assumptions that matter before deploying a local LLM server.

## Quick Read

If you only need the current working assumptions, they are:

1. Host: HP Z8 G4 (headless, dedicated to Local_LLM).
2. Hostname: `Skippy`.
3. IP: `192.168.128.5`.
4. Admin user: `Daniel`.
5. GPUs: `3` RTX 4060 cards, all dedicated to Local_LLM inference.
6. Storage: SSD 1 for OS, SSD 2 for Local_LLM, RAID10 for media, SMB share for transfers only.

## Environment Picture

```mermaid
flowchart TD
	A[Skippy] --> B[Ubuntu Server]
	A --> C[3 RTX 4060 GPUs]
	A --> D[2 SSDs]
	A --> E[4 HDD RAID10]
	A --> F[SMB Share]
	C --> C1[All 3 GPUs for Local_LLM]
	D --> D1[SSD 1 for OS]
	D --> D2[SSD 2 for /var/lib/ollama and /var/lib/docker]
	E --> E1[/srv/media]
	F --> F1[Transfers and collaboration]
```

## Target Platform

1. HP Z8 G4 server running Ubuntu Server 26.04 LTS in headless mode.
2. SSH administrative access.
3. LAN connectivity for browser clients.

## Current Target Identity

1. Hostname target: `Skippy`
2. LAN FQDN target: `Skippy.aybara.local`
3. Planned LAN IP: `192.168.128.5`
4. Planned Ubuntu administrative user: `Daniel`

## Current Known Hardware

1. Workstation class host: HP Z8 G4.
2. Installed RAM: `128 GB`.
3. Installed GPUs: `3` NVIDIA GeForce RTX 4060.
4. Installed SSDs: `2` HP SSD FX900 Pro M.2 `1 TB` drives.
5. Installed HDDs: `4` physical `1 TB` drives attached to the RAID controller.
6. Available LAN share: `\\192.168.128.4\Storage` using `Daniel`.

These facts make the first deployment clearly GPU-accelerated rather than CPU-only.

## Human Summary

The current host plan is already specific enough to build:

1. The machine is known.
2. The network identity is known.
3. The GPU split is known in principle.
4. The storage roles are known.
5. Only a few host-specific details still need to be confirmed live.

## Current Resource Allocation Assumption

1. All `3` GPUs dedicated to Local_LLM inference workloads.
2. SSD 1 should prioritize OS stability and performance.
3. SSD 2 should prioritize Local_LLM models, Docker, and fast service data.
4. The four HDDs should be treated as a RAID-backed media array rather than part of the fast LLM path.
5. The `\\192.168.128.4\Storage` share should be treated as shared network storage rather than a performance tier for Local_LLM.

## Required Host Facts To Capture

1. Hostname and IP address.
2. Linux distribution and version.
3. CPU model and core count.
4. Installed RAM.
5. GPU model, driver state, and available VRAM if present.
6. Available disk capacity for models and logs.
7. Whether the host is bare metal, VM, or container-backed.

## Service Decisions To Capture

1. Selected model runtime.
2. Selected web UI.
3. Initial model set.
4. Publication method for LAN users.
5. Authentication expectations.
6. Backup expectations for configuration and user data.

## Network Dependencies

1. Local DNS if a named endpoint will be published.
2. Reverse proxy if HTTPS or unified access control is desired.
3. Sufficient LAN bandwidth for concurrent browser sessions.

## Open Questions

1. Which physical GPU indices map to the `3` Local_LLM GPUs?
2. How much free disk space will remain on SSD 2 after Local_LLM models and services are installed?
3. Should the SMB share be mounted on the Ubuntu host, mapped only on Windows operator systems, or both for the first rollout?
4. How many concurrent users need acceptable performance? 1
5. Is the first target conversational use, document assistance, coding help, or a mix? Mix
6. Should the first rollout be operator-only or available to other local users immediately?

## What Is Already Decided Versus Still Unknown

Already decided:

1. Host class and hardware family.
2. Primary hostname, IP, and admin user.
3. High-level GPU split.
4. High-level storage layout.
5. LAN-only first rollout.

Still unknown until the host is live:

1. Exact GPU numbering from `nvidia-smi -L`.
2. Final free space after software installation.
3. Exact SMB mount behavior on Ubuntu, if needed.
4. Real user concurrency and model pressure.