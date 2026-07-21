# Local LLM

## Purpose

This project defines how to deploy a local large language model server on Debian or Ubuntu so AI interactions can be served to users on the local network.

The immediate goal is to establish a practical baseline for model hosting, web access, hardware sizing, and safe LAN-only exposure.

## Start Here

If you are the person building or operating the host, start with `docs/start-here.md`.

### Quickest Path: Automated Deployment (Recommended)

The easiest way to get Skippy operational:

1. Read: `docs/skippy-automated-deployment-guide.md` (complete automation overview)
2. Run: `src/invoke-skippy-usb-automation.ps1` on Windows with password hash (2 minutes)
3. Boot: Z8 G4 from prepared USB with GRUB autoinstall parameter (1 keystroke)
4. Wait: ~30-50 minutes while Ubuntu installs + Local_LLM bootstraps automatically
5. Verify: SSH in and confirm services are running

**Total time: ~30-50 minutes, almost entirely automatic.**

### Alternative Path: Manual Command-by-Command

If you prefer step-by-step control:

Recommended reading order:

1. `docs/start-here.md`
2. `docs/boot-day-checklist.md`
3. `docs/z8g4-host-prep-checklist.md`
4. `docs/storage-layout.md`
5. `docs/first-build-execution-checklist.md`
6. `docs/z8g4-install-commands.md`
7. `docs/skippy-post-install-command-sequence.md`
8. `docs/post-install-server-validation.md`

## Automation Infrastructure

**New in this release:** Complete hands-off automation for deployment.

**What's automated:**
- Ubuntu Server 26.04 LTS installation (unattended preseed)
- First-boot systemd service that runs after OS installs
- Docker installation
- NVIDIA driver detection and installation
- Ollama setup with all 3 GPUs dedicated to inference
- Open WebUI deployment
- Health monitoring with automatic periodic checks
- Comprehensive logging and audit trail

**Key automation files** (in `src/`):
- `invoke-skippy-usb-automation.ps1` - Master orchestrator (Windows)
- `prepare-ubuntu-server-26.04-usb-autoinstall.ps1` - USB preparation (Windows)
- `bootstrap-local-llm-host.sh` - Main bootstrap script (Linux)
- `local-llm-first-boot.service` & `local-llm-first-boot-runner.sh` - First-boot automation (Linux)
- `local-llm-health-check.sh` + timer - Periodic health monitoring (Linux)
- `skippy-preseed.cfg` - Ubuntu unattended install config

**Deployment flow:**
```
Windows (2 min)        Boot from USB (1 step)      Linux automation (30-50 min)
  Prepare USB      →    GRUB parameter      →       Full bootstrap
  Password hash   →    Auto-install       →       Services running
                                                    Ready for use
```

See `docs/skippy-automated-deployment-guide.md` for complete walkthrough.

1. Host and hardware planning for a local LLM server.
2. Model-serving and web UI platform options.
3. Network exposure, reverse-proxy, and access-control considerations.
4. A phased implementation plan for a first local deployment.
5. Environment inventory and deployment assumptions for Debian or Ubuntu.

This project does not yet cover public internet exposure, multi-node inference clustering, or fine-tuning workflows.

## Recommended Direction

The current recommended direction is:

1. Use the HP Z8 G4 as a dedicated Local_LLM host rather than a mixed creative workstation.
2. Prefer Ubuntu Server 26.04 LTS for the current headless build path.
3. Treat the older mixed-workstation material in this repository as optional reference, not as the primary install path.
4. Start with Ollama as the initial local model runtime because it is simple to operate and is the fastest path to a working GPU-backed LAN deployment.
5. Use Open WebUI or a similarly lightweight browser front end for LAN users.
6. Keep the first deployment LAN-only behind an existing reverse proxy if named HTTPS access is needed.
7. Treat the three NVIDIA GeForce RTX 4060 GPUs as separate acceleration devices rather than assuming their VRAM can be pooled automatically into one larger model budget.
8. Start with quantized models that fit comfortably on a single GPU, then revisit higher-performance runtimes only if concurrency or larger-context requirements justify the added complexity.
9. Expose all three GPUs to inference by default unless you deliberately reintroduce a local desktop or console-driven workload.

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

The initial target is a Debian or Ubuntu server-class host that will serve one or more open-weight LLMs to users on the local network.

The first identified hardware target is an HP Z8 G4 host with `128 GB` of RAM and `3` NVIDIA GeForce RTX 4060 GPUs. This is a strong starting point for a local inference server, but the deployment plan should still assume that each GPU has its own VRAM ceiling and that not every runtime will distribute a single model cleanly across all three cards.

The current named target is `Skippy.aybara.local` at `192.168.128.5` with Ubuntu administrative access under `daniel`. The current hardware layout also includes `2` HP SSD FX900 Pro M.2 `1 TB` drives. The intended GPU posture is now explicit: all `3` GPUs are available to Local_LLM by default for the dedicated-server path.

The storage posture is now also explicit. For Skippy, optimize for Local_LLM first: use SSD 1 for Ubuntu Server and base system state, SSD 2 for Local_LLM hot data such as models and Docker state, and the four 1 TB RAID-attached hard drives as a RAID10 bulk-data area for colder model artifacts, exports, datasets, or archives.

Shared storage is also part of the operating model. Use `\\192.168.128.6\Storage` as a mapped SMB location for transfer, exports, and collaboration, but keep it out of the primary Local_LLM runtime path. When persistent access is needed on Ubuntu, mount it with a root-owned credentials file rather than embedding the password in repo docs.

Named DNS, reverse proxy, and operational tooling can be integrated later, but they are optional layers around this project rather than requirements for the first Local_LLM deployment.

The first implementation should assume:

1. LAN-only reachability.
2. Operator access over SSH.
3. No local desktop requirement for the first production build.
4. Browser-based user access.
5. Moderate concurrency for a small number of users rather than broad enterprise-scale load.
6. Initial model choices should favor efficient 7B to 14B class quantized models unless later validation proves a larger stack is warranted.
7. All three GPUs should remain available to inference unless a later change introduces a local desktop or other competing workload.

## Project Files

1. `docs/architecture-options.md` compares viable local LLM serving stacks for the first deployment.
2. `docs/start-here.md` is the fastest entry point for a human operator.
3. `docs/implementation-plan.md` defines the rollout sequence for the initial server.
4. `docs/environment-inventory.md` records the target host assumptions, hardware questions, and service dependencies.
5. `docs/ubuntu-server-26.04-install-runbook.md` defines the recommended first build path for the HP Z8 G4 on Ubuntu Server 26.04 LTS for the current headless deployment.
6. `docs/z8g4-host-prep-checklist.md` captures the BIOS, storage, network, and GPU-role decisions that should be made before install.
7. `docs/gpu-reservation-and-layout.md` documents the dedicated-host and mixed-workstation GPU operating modes.
8. `docs/first-build-execution-checklist.md` provides the operator-facing step-by-step order for the first Z8 G4 build.
9. `docs/z8g4-install-commands.md` provides the exact Windows-to-Ubuntu copy and install commands for the first host build.
10. `docs/creative-app-compatibility.md` records the current Linux fit for Resolve, Blender, OBS, VS Code, browser-based notes, and free CAD options.
11. `docs/resolve-nvidia-prep.md` captures the conservative driver and GPU-sharing posture needed for DaVinci Resolve on the mixed workstation.
12. `docs/cad-selection.md` compares the first free CAD validation options for Linux on this host.
13. `docs/storage-layout.md` fixes the Skippy disk layout around LLM-first performance and RAID10-backed media storage.
14. `docs/post-install-server-validation.md` validates that Skippy is operational as a headless Local_LLM server after the base build.
15. `docs/standalone-repository-checklist.md` defines the minimum file set and validation steps for promoting this project into its own repository.
16. `LICENSE.md` defines this repository as private and internal-use only rather than open source.
17. `CONTRIBUTING.md` defines the expected contribution and validation posture for standalone use.
18. `src/README.md` summarizes the initial host-side helper scripts and service scaffolding.
19. `src/apply-ollama-gpu-policy.sh` generates an Ollama systemd override from the Local_LLM environment file so reserved-GPU mode is operational rather than doc-only.
20. `docs/boot-day-checklist.md` provides a condensed install-day sequence for the current Ubuntu Server 26.04 build.
21. `docs/skippy-post-install-command-sequence.md` provides the condensed post-install command path tailored to Skippy.

## Dependencies

This project is expected to depend on:

1. Optional local DNS and reverse-proxy tooling if named HTTPS access is desired.
2. Debian or Ubuntu package management plus vendor install methods for the selected model runtime.
3. Sufficient local compute, memory, and storage for the chosen model sizes.
