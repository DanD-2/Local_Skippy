# Local LLM

## Purpose

This project defines how to deploy a local large language model server on Debian or Ubuntu so AI interactions can be served to users on the local network.

The immediate goal is to establish a practical baseline for model hosting, web access, hardware sizing, and safe LAN-only exposure.

## Start Here

If you are the person building or operating the host, start with `docs/start-here.md`.

Recommended reading order:

1. `docs/start-here.md`
2. `docs/z8g4-host-prep-checklist.md`
3. `docs/storage-layout.md`
4. `docs/first-build-execution-checklist.md`
5. `docs/z8g4-install-commands.md`
6. `docs/post-install-workstation-validation.md`

Quick operator summary:

1. Finish the host decisions before installing Ubuntu.
2. Install Ubuntu Studio and the NVIDIA driver.
3. Validate GPU numbering before editing the environment file.
4. Install Ollama, Open WebUI, and the repository helper files.
5. Test locally first, then from another LAN machine.
6. Add shared storage only as a convenience layer, not as part of the hot LLM path.

## Scope

This project covers:

1. Host and hardware planning for a local LLM server.
2. Model-serving and web UI platform options.
3. Network exposure, reverse-proxy, and access-control considerations.
4. A phased implementation plan for a first local deployment.
5. Environment inventory and deployment assumptions for Debian or Ubuntu.

This project does not yet cover public internet exposure, multi-node inference clustering, or fine-tuning workflows.

## Recommended Direction

The current recommended direction is:

1. Use the HP Z8 G4 workstation as a mixed creative workstation plus Local_LLM host rather than treating it as a dedicated inference appliance.
2. Prefer Ubuntu Studio 24.04 LTS over generic Ubuntu Desktop when the same machine must support interactive media creation and CAD work under Linux.
3. If the required creative toolchain is Windows-first rather than Linux-friendly, treat a Linux-only bare-metal build as a bad fit and revisit either a separate LLM host or a Linux guest/runtime strategy.
4. Start with Ollama as the initial local model runtime because it is simple to operate and is the fastest path to a working GPU-backed LAN deployment.
5. Use Open WebUI or a similarly lightweight browser front end for LAN users.
6. Keep the first deployment LAN-only behind an existing reverse proxy if named HTTPS access is needed.
7. Treat the three NVIDIA GeForce RTX 4060 GPUs as separate acceleration devices rather than assuming their VRAM can be pooled automatically into one larger model budget.
8. Start with quantized models that fit comfortably on a single GPU, then revisit higher-performance runtimes only if concurrency or larger-context requirements justify the added complexity.
9. Reserve one GPU for display and creative workloads by default, and expose only the remaining GPUs to inference unless later testing proves the desktop remains stable under heavier sharing.

## Repository Independence

This project is intended to be self-contained.

You should be able to copy the `Local_LLM` directory into its own repository without bringing the rest of the Series3 tree with it.

To keep that true:

1. All operator runbooks should work from the Local_LLM repository root.
2. All helper artifacts required for the first build should stay under `src/` in this project.
3. Reverse proxy, DNS, monitoring, and backup tooling should be treated as optional integrations rather than hidden dependencies on another repository.

## Standalone Repository Bootstrap

If you want to promote this directory into its own repository, treat this folder as the repository root.

The minimum standalone repository contents are:

1. `README.md`
2. `.gitignore`
3. `LICENSE.md`
4. `CONTRIBUTING.md`
5. `docs/`
6. `src/`

Suggested bootstrap flow from the Local_LLM root:

```powershell
git init
git add .
git commit -m "Initial Local_LLM import"
```

Use `docs/standalone-repository-checklist.md` when copying this project into a new top-level repository so the move stays minimal and repeatable.

## Current Environment

The initial target is a Debian or Ubuntu workstation-class host that will serve both interactive creative workloads and one or more open-weight LLMs for local-network use.

The first identified hardware target is an HP Z8 G4 workstation with `128 GB` of RAM and `3` NVIDIA GeForce RTX 4060 GPUs. This is a strong starting point for a local inference server, but the deployment plan should still assume that each GPU has its own VRAM ceiling and that not every runtime will distribute a single model cleanly across all three cards.

The current named target is `Skippy.aybara.local` at `192.168.128.5` with Ubuntu administrative access under `Daniel`. The current hardware layout also includes `2` HP SSD FX900 Pro M.2 `1 TB` drives. The intended GPU posture is now explicit: `2` GPUs for Local_LLM and `1` GPU reserved for desktop, editing, CAD, and general workstation use.

The storage posture is now also explicit. For Skippy, optimize for Local_LLM first and video editing second: use SSD 1 for Ubuntu Studio and workstation responsiveness, SSD 2 for Local_LLM hot data such as models and Docker state, and the four 1 TB RAID-attached hard drives as a RAID10 media array for bulk creative project storage.

Shared storage is also part of the operating model. Use `\\192.168.128.6\Storage` as a mapped SMB location for transfer, exports, and collaboration, but keep it out of the primary Local_LLM runtime path. When persistent access is needed on Ubuntu, mount it with a root-owned credentials file rather than embedding the password in repo docs.

Named DNS, reverse proxy, and operational tooling can be integrated later, but they are optional layers around this project rather than requirements for the first Local_LLM deployment.

The first implementation should assume:

1. LAN-only reachability.
2. Operator access over SSH.
3. Interactive local workstation use for video editing and CAD work.
4. Browser-based user access.
5. Moderate concurrency for a small number of users rather than broad enterprise-scale load.
6. Initial model choices should favor efficient 7B to 14B class quantized models unless later validation proves a larger stack is warranted.
7. One GPU should remain reserved for desktop and creative application stability unless proven unnecessary.

## Project Files

1. `docs/architecture-options.md` compares viable local LLM serving stacks for the first deployment.
2. `docs/start-here.md` is the fastest entry point for a human operator.
3. `docs/implementation-plan.md` defines the rollout sequence for the initial server.
4. `docs/environment-inventory.md` records the target host assumptions, hardware questions, and service dependencies.
5. `docs/ubuntu-24.04-install-runbook.md` defines the recommended first build path for the HP Z8 G4 on Ubuntu 24.04 LTS, with Ubuntu Studio as the preferred Linux option for mixed workstation use.
6. `docs/z8g4-host-prep-checklist.md` captures the BIOS, storage, network, and GPU-role decisions that should be made before install.
7. `docs/gpu-reservation-and-layout.md` documents the dedicated-host and mixed-workstation GPU operating modes.
8. `docs/first-build-execution-checklist.md` provides the operator-facing step-by-step order for the first Z8 G4 build.
9. `docs/z8g4-install-commands.md` provides the exact Windows-to-Ubuntu copy and install commands for the first host build.
10. `docs/creative-app-compatibility.md` records the current Linux fit for Resolve, Blender, OBS, VS Code, browser-based notes, and free CAD options.
11. `docs/resolve-nvidia-prep.md` captures the conservative driver and GPU-sharing posture needed for DaVinci Resolve on the mixed workstation.
12. `docs/cad-selection.md` compares the first free CAD validation options for Linux on this host.
13. `docs/storage-layout.md` fixes the Skippy disk layout around LLM-first performance and RAID10-backed media storage.
14. `docs/post-install-workstation-validation.md` validates that Resolve, OBS, CAD, browser workflows, and Local_LLM can coexist acceptably on Skippy.
15. `docs/standalone-repository-checklist.md` defines the minimum file set and validation steps for promoting this project into its own repository.
16. `LICENSE.md` defines this repository as private and internal-use only rather than open source.
17. `CONTRIBUTING.md` defines the expected contribution and validation posture for standalone use.
18. `src/README.md` summarizes the initial host-side helper scripts and service scaffolding.
19. `src/apply-ollama-gpu-policy.sh` generates an Ollama systemd override from the Local_LLM environment file so reserved-GPU mode is operational rather than doc-only.

## Dependencies

This project is expected to depend on:

1. Optional local DNS and reverse-proxy tooling if named HTTPS access is desired.
2. Debian or Ubuntu package management plus vendor install methods for the selected model runtime.
3. Sufficient local compute, memory, and storage for the chosen model sizes.
