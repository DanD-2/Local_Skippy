# Ubuntu 24.04 Install Runbook For Local LLM

## Purpose

Use this runbook to build the first Local_LLM host on the HP Z8 G4 workstation with Ubuntu 24.04 LTS.

The target outcome is a LAN-reachable LLM server with NVIDIA drivers, Ollama, and Open WebUI installed in a maintainable baseline configuration.

## Short Version

If you want the shortest safe path, do this in order:

1. Finish the host decisions before installing Ubuntu.
2. Install Ubuntu Studio 24.04 LTS and confirm SSH works.
3. Install the NVIDIA driver and record `nvidia-smi -L` output.
4. Install Docker and Ollama.
5. Install the Local_LLM helper files from `src/`.
6. Set the GPU list in `/etc/default/local-llm`.
7. Enable Open WebUI.
8. Test locally first.
9. Test from another LAN machine second.

## Build Picture

```mermaid
flowchart TD
    A[Prep decisions] --> B[Ubuntu install]
    B --> C[SSH and updates]
    C --> D[NVIDIA driver]
    D --> E[Docker]
    E --> F[Ollama]
    F --> G[Local_LLM helper files]
    G --> H[Open WebUI]
    H --> I[Local validation]
    I --> J[LAN validation]
```

## Stop Rules

Do not continue to the next phase if any of these are still broken:

1. SSH access does not work.
2. `nvidia-smi` does not show all expected GPUs.
3. Docker or Ollama does not start cleanly.
4. Open WebUI does not answer locally on `http://127.0.0.1:3000`.

## Recommended Host Baseline

1. Ubuntu Studio 24.04 LTS when the same machine must support interactive media creation and CAD work under Linux.
2. SSH enabled during install.
3. Static or DHCP-reserved LAN address.
4. One administrative user plus `sudo` access.

For the current Skippy target, read `docs/storage-layout.md` before installation so the SSD, RAID10, and SMB-share roles stay consistent.

## Why Ubuntu 24.04

1. Ubuntu 24.04 LTS is the best first-fit balance between stability and current NVIDIA support.
2. Ubuntu is better documented than Debian for consumer RTX AI workloads.
3. Broad community coverage exists for Ollama, Docker, Open WebUI, and Linux creative tooling.
4. Ubuntu Studio is the better fit when the machine must remain an interactive workstation with media-creation duties.

## Pre-Install Decisions

Capture these before touching the workstation:

1. Final hostname.
2. Planned LAN IP address or DHCP reservation.
3. Whether one RTX 4060 must remain reserved for console or display use.
4. Whether model storage should live on the OS disk or a separate data volume.
5. Whether the first rollout is operator-only or multi-user on day one.
6. Whether the target creative applications are Linux-native or Windows-first.

Use `docs/z8g4-host-prep-checklist.md` to complete these decisions before the OS install starts.

If the required creative applications are Windows-first, stop here and revisit the host-OS choice before continuing with a Linux bare-metal plan.

## Installation Sequence

Human note:

Use `docs/z8g4-install-commands.md` when you want exact commands. Use this runbook when you want the logic behind the order.

## Phase 1: Base OS Install

1. Install Ubuntu 24.04 LTS on the Z8 G4.
2. Enable OpenSSH Server during setup.
3. Apply all available package updates after first boot.
4. Confirm remote SSH access works before proceeding with AI tooling.

For the current mixed-workstation requirement, prefer Ubuntu Studio 24.04 LTS unless you have already decided the box will not run interactive creative applications under Linux.

Suggested validation:

```sh
hostnamectl
lsb_release -a
ip address
sudo apt update
sudo apt full-upgrade -y
```

Operator checkpoints:

1. The host boots cleanly.
2. SSH works from the operator machine.
3. The host has current updates before GPU tooling is installed.

## Phase 2: NVIDIA Driver Baseline

1. Confirm the three RTX 4060 cards are visible to the OS.
2. Install the recommended Ubuntu NVIDIA driver.
3. Reboot if required.
4. Validate `nvidia-smi` sees the intended GPUs.

Suggested validation:

```sh
lspci | grep -i nvidia
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot
nvidia-smi
nvidia-smi -L
```

Expected result:

1. All three GPUs appear in `nvidia-smi`.
2. Driver version is current on the Ubuntu-supported path.
3. No card is missing unexpectedly.

If one GPU must remain reserved for workstation use, document the intended device numbering now and apply the mixed-workstation guidance from `docs/gpu-reservation-and-layout.md` after the base runtime install.

Operator checkpoints:

1. All three GPUs appear.
2. You know which GPU will remain reserved for the workstation.
3. You have written down the real GPU numbering.

## Phase 3: Container And Runtime Prerequisites

1. Install Docker Engine using the Ubuntu-supported package path or the standard path you choose for this repository.
2. Enable Docker at boot.
3. Install NVIDIA container support only if the chosen Open WebUI deployment path needs GPU-aware containers later.

Suggested validation:

```sh
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo systemctl status docker --no-pager
docker --version
```

Operator checkpoints:

1. Docker is active.
2. Docker starts at boot.

## Phase 4: Ollama Install

1. Install Ollama on the host.
2. Start and enable the Ollama service.
3. Pull a small test model first.
4. Run a prompt locally from the shell.

Suggested validation:

```sh
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable --now ollama
systemctl status ollama --no-pager
ollama pull llama3.1:8b
ollama run llama3.1:8b "Respond with the word ready."
```

Operator note:

Start with one single-GPU-friendly quantized model. Do not begin by chasing the largest model that might barely fit.

If you need to reserve one GPU for workstation use, add an Ollama systemd override that constrains `CUDA_VISIBLE_DEVICES` after confirming the intended device numbering with `nvidia-smi -L`.

Preferred repository-backed path:

1. Copy `src/local-llm.env.example` to `/etc/default/local-llm`.
2. Set `LOCAL_LLM_GPU_DEVICES` to the desired inference device list.
3. Install `src/apply-ollama-gpu-policy.sh` as `/usr/local/bin/apply-ollama-gpu-policy.sh`.
4. Run `/usr/local/bin/apply-ollama-gpu-policy.sh`.
5. Run `systemctl daemon-reload && systemctl restart ollama`.

Operator checkpoints:

1. Ollama runs locally.
2. The first model responds.
3. The GPU decision is reflected in the environment file before user access is enabled.

## Phase 5: Open WebUI Install

The simplest first deployment path is a containerized Open WebUI instance that talks to local Ollama.

The repository now includes host-side scaffolding for this deployment:

1. `src/local-llm.env.example`
2. `src/run-open-webui.sh`
3. `src/local-llm-open-webui.service`
4. `src/apply-ollama-gpu-policy.sh`

Suggested deployment:

```sh
sudo docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

Preferred operational path:

1. Copy `src/local-llm.env.example` to `/etc/default/local-llm`.
2. Install `src/run-open-webui.sh` as `/usr/local/bin/local-llm-run-open-webui.sh`.
3. Install `src/local-llm-open-webui.service` under `/etc/systemd/system/`.
4. If using reserved-GPU mode, install and run `src/apply-ollama-gpu-policy.sh` before enabling user-facing services.
5. Run `systemctl daemon-reload` and `systemctl enable --now local-llm-open-webui.service`.

Suggested validation:

```sh
sudo docker ps
curl -I http://127.0.0.1:3000
```

Operator checkpoints:

1. The Open WebUI container is running.
2. The local WebUI endpoint answers.

## Phase 6: LAN Publication

1. Keep the first deployment LAN-only.
2. Validate direct access on `http://host-or-ip:3000` first.
3. Only add reverse-proxy publication after the direct path works cleanly.
4. If HTTPS publication is desired, add any DNS and reverse-proxy layer as an explicit follow-up rather than a hidden prerequisite.

Human rule:

Do not add DNS or reverse proxy until the direct IP path already works.

## Phase 7: First Operational Checks

1. Confirm Ollama restarts cleanly after reboot.
2. Confirm Open WebUI starts automatically.
3. Record model storage location and disk consumption.
4. Record which GPU or GPUs are intended for inference.
5. Run the repository validation helper after installation changes.

Suggested validation:

```sh
systemctl status ollama --no-pager
systemctl status local-llm-open-webui.service --no-pager
sudo docker ps
nvidia-smi
df -h
/usr/local/bin/validate-local-llm.sh
```

Operator checkpoints:

1. Ollama restarts after reboot.
2. Open WebUI restarts after reboot.
3. The final disk usage matches the intended SSD and RAID roles.

## Recommended First Models

Start with one of these model classes:

1. A 7B to 8B instruct model as the primary baseline.
2. A second smaller fallback model for fast smoke tests.

Do not treat 128 GB of system RAM as a substitute for GPU VRAM when choosing the first production model.

## Hardening Follow-Up

After the base deployment works, add:

1. A named DNS endpoint.
2. Reverse-proxy publication if browser UX should match the rest of the local platform.
3. Backup guidance for Open WebUI state and Ollama model inventory.
4. Monitoring for host reachability, Ollama service health, and web UI availability.

## Minimum Success Criteria

The host build is successful when:

1. Ubuntu 24.04 is updated and remotely reachable.
2. `nvidia-smi` shows the expected RTX 4060 devices.
3. Ollama answers a local prompt successfully.
4. Open WebUI is reachable from another LAN machine.
5. The deployment can be rebooted without manual recovery steps.