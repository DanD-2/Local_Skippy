# Storage Layout

## Purpose

Use this layout for the Skippy server so the machine is optimized for AI inference and container operations.

This is a headless server. There are no media, creative, or workstation storage requirements.

## Current Storage Inventory

1. `2` HP SSD FX900 Pro M.2 `1 TB` drives.
2. `4` physical `1 TB` hard drives attached to the RAID controller (spare — not used for primary AI path).

## Design Priorities

1. AI model reads and writes come first.
2. Container and service state are fast-path.
3. OS and packages are stable and isolated from AI data.
4. Logs and evaluation reports are on the OS disk unless they grow large.

## Storage Picture

```mermaid
flowchart TD
    A[Skippy Storage] --> B[SSD 1]
    A --> C[SSD 2]
    B --> B1[Ubuntu Server OS]
    B --> B2[/ and /home]
    B --> B3[Logs and config]
    C --> C1[/var/lib/ollama — models]
    C --> C2[/var/lib/docker — container state]
    C --> C3[/srv/agent-data — optional agent workspace]
```

## SSD 1: OS

Use the first 1 TB SSD for:

1. Ubuntu Server 24.04 LTS.
2. System packages and service binaries.
3. User home directories.
4. System logs under `/var/log`.
5. Service config files under `/etc`.

Suggested layout:

1. `/` on SSD 1.
2. `/home` on SSD 1.

## SSD 2: AI Data

Use the second 1 TB SSD for the AI and container hot path.

Recommended mount targets:

1. `/var/lib/ollama` — Ollama model storage and state.
2. `/var/lib/docker` — Docker container data, Open WebUI volume.
3. `/srv/agent-data` — optional per-agent workspace or scratch area.

Reasoning:

1. Keeps model pulls, model reads, container state, and Open WebUI data off the OS disk.
2. Prevents AI I/O from competing with the OS SSD on heavy inference cycles.
3. Gives the AI stack the fastest storage available after RAM and GPU.

## HDD Array

The four 1 TB HDDs are available as spare capacity.

Possible uses in this project:

1. Archive models that are not in active use.
2. Evaluation logs and weekly report archives if SSD 2 grows constrained.
3. Backup snapshots.

Do not use the HDD array for:

1. `/var/lib/ollama` (active model storage).
2. `/var/lib/docker` (container state).
3. Any hot AI inference path.

## Recommended Mount Model

1. SSD 1: `/`
2. SSD 2: `/var/lib/ollama` and `/var/lib/docker`
3. HDD array: optional archive only — `/srv/archive` if used

## Success Criteria

The layout is correct when:

1. The OS and services boot cleanly from SSD 1.
2. Ollama model access is SSD 2-backed.
3. Docker and Open WebUI state is SSD 2-backed.
4. Disk usage on SSD 2 is monitored and does not silently fill the volume.