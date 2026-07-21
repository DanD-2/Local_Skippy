# Skippy Storage Layout

## Purpose

Use this layout for the Skippy server so the machine is optimized for Local_LLM first while keeping cold data and optional shared storage off the hot runtime path.

## Current Storage Inventory

1. `2` HP SSD FX900 Pro M.2 `1 TB` drives.
2. `4` physical `1 TB` hard drives attached to the RAID controller.
3. Remote LAN share: `\\192.168.128.6\Storage`.

## Design Priorities

1. LLM runtime and model responsiveness come first.
2. Predictable service behavior comes second.
3. Capacity is less important than fast active working sets.
4. Avoid storing hot LLM data on spinning disks.
5. Keep shared network storage available for ingress, exports, and collaboration, but not for hot model reads.

## Storage Picture

```mermaid
flowchart TD
	A[Skippy Storage] --> B[SSD 1]
	A --> C[SSD 2]
	A --> D[RAID10 HDD Array]
	A --> E[SMB Share]
	B --> B1[Ubuntu Server and base tools]
	B --> B2[/ and /home]
	C --> C1[/var/lib/ollama]
	C --> C2[/var/lib/docker]
	C --> C3[Optional /srv/fast-work]
	D --> D1[/srv/media]
	D --> D2[Bulk data and exports]
	E --> E1[Transfers and collaboration only]
	E --> E2[Not for model storage]
```

## Remember This

1. SSD 1 keeps the host simple and bootable.
2. SSD 2 keeps Local_LLM fast.
3. RAID10 keeps large non-hot data local without stealing SSD space.
4. The SMB share is only a convenience layer.

## Recommended Layout

## SSD 1: OS And Base Packages

Use the first 1 TB SSD for:

1. Ubuntu Server 26.04 LTS.
2. Base administrative packages.
3. User home directories.

Suggested posture:

1. `/` on SSD 1.
2. `/home` on SSD 1 unless you later have a strong reason to split it.

## SSD 2: Local_LLM Fast Data

Use the second 1 TB SSD for the LLM and container hot path.

Recommended mount targets:

1. `/var/lib/ollama`
2. `/var/lib/docker`
3. Optional shared fast workspace such as `/srv/fast-work`

Reasoning:

1. Keeps model pulls, model reads, container state, and Open WebUI data off the OS disk.
2. Prevents LLM I/O from fighting the OS and administrative tasks on the OS SSD.
3. Gives the LLM stack the fastest storage available after RAM and GPU.

## HDD Array: Bulk Data

Use the four 1 TB HDDs as a RAID10 array.

Recommended role:

1. Larger datasets that do not need SSD latency.
2. Exports, logs, and artifacts that do not belong on SSD 2.
3. Bulk archives that do not belong on the LLM SSD.

Why RAID10:

1. Better write behavior than parity RAID for general bulk data.
2. Better resilience than RAID0 while still favoring speed over raw capacity.
3. Appropriate for the stated preference of predictable throughput over maximum capacity.

Do not use the HDD RAID set for:

1. `/var/lib/ollama`
2. `/var/lib/docker`
3. Primary model storage

## Remote LAN Share: Shared Transfer And Collaboration Storage

Use the remote SMB share `\\192.168.128.6\Storage` as a mapped shared location, not as part of the primary Skippy performance path.

Recommended role:

1. Project ingress and egress.
2. Shared exports and deliverables.
3. Cross-machine handoff storage.
4. Optional shared mount on Ubuntu at `/mnt/storage` for operator convenience.

Do not use the remote share for:

1. `/var/lib/ollama`
2. `/var/lib/docker`
3. Resolve cache or other latency-sensitive scratch data
4. Primary active model storage

Credential handling:

1. Do not store the SMB password directly in repository markdown.
2. On Windows, enter the credential at mapping time.
3. On Ubuntu, store the credential in a root-owned file such as `/root/.smb-skippy-storage` with `600` permissions if a persistent mount is needed.

## Recommended Mount Model

Use a simple first layout:

1. SSD 1: `/`
2. SSD 2: `/var/lib/ollama` and `/var/lib/docker`
3. RAID10 HDD array: `/srv/media`
4. Remote SMB share: mapped separately for shared storage access only

Optional follow-up:

1. Add `/srv/fast-work` on SSD 2 if you want a dedicated scratch area for smaller active LLM-adjacent or project files.

## Operational Notes

1. LLM model storage should stay on SSD 2.
2. Docker data should stay on SSD 2.
3. Large datasets, exports, and general bulk data should live on `/srv/media`.
5. Use `\\192.168.128.6\Storage` for shared transfers and collaborative storage, not for the main Local_LLM runtime path.

## Success Criteria

The layout is correct when:

1. The OS remains responsive under normal service and maintenance use.
2. Local_LLM model access is SSD-backed.
3. Bulk non-hot data is offloaded to the HDD RAID10 array.
4. The remote share is available for shared storage without becoming a dependency for core inference performance.
5. The storage plan reflects speed-first priorities rather than maximum capacity.