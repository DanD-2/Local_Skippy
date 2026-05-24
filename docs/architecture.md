# Architecture — Local Skippy Dedicated AI Server

## Mission

Local Skippy is a single-host, headless AI appliance.  Its only job is to run four Hermes AI agents
and expose them to LAN users and approved remote clients.  There is no desktop environment, no
creative tooling, and no shared workstation use.

## Host Role

| Attribute    | Value                                      |
|--------------|--------------------------------------------|
| Hostname     | `skippy.aybara.local` / `192.168.128.5`    |
| OS           | Ubuntu Server 24.04 LTS (no GUI)           |
| Admin access | SSH only                                   |
| User access  | Browser (Open WebUI) or VS Code Remote SSH |
| GPU posture  | All three RTX 4060 GPUs dedicated to AI    |
| RAM posture  | System RAM used as inference overflow       |
| CPU posture  | Up to 75 % utilization for AI overflow     |

## Component Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    LAN Clients                              │
│  Browser (Open WebUI)  │  VS Code Remote SSH               │
└───────────┬────────────┴──────────────────┬────────────────┘
            │ HTTP :3000                    │ SSH :22
┌───────────▼────────────────────────────────▼───────────────┐
│                  Ubuntu Server 24.04 LTS                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Open WebUI  (Docker container, port 3000)          │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │ Ollama API :11434                  │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │  Ollama  (systemd service)                          │   │
│  │  Models stored on SSD 2 (/var/lib/ollama)           │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │ CUDA / ROCm                        │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │  3 × NVIDIA GeForce RTX 4060  (all dedicated to AI) │   │
│  │  Overflow → 128 GB System RAM                       │   │
│  │  Overflow → CPU  (≤ 75 % policy target)             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Four Hermes Agents

Each agent is an Open WebUI workspace profile that routes to a dedicated Ollama model instance.
Agent isolation is achieved through separate system prompts, model assignments, and (where needed)
resource priority.

| Agent               | Model (default local)             | Priority   | Access path              |
|---------------------|-----------------------------------|------------|--------------------------|
| Finance             | `nous-hermes2:34b-q4_K_M`         | Highest    | Open WebUI browser       |
| Infrastructure      | `nous-hermes2:13b-q4_K_M`         | High       | Open WebUI browser       |
| Software Engineering| `nous-hermes2-mixtral:8x7b-q4_K_M`| Normal     | Open WebUI + VS Code     |
| Evaluator           | `nous-hermes2:13b-q4_K_M`         | Low        | Open WebUI (scheduled)   |

See `docs/agent-topology.md` for full model rationale and online-model alternatives.
See `docs/model-recommendations.md` for complete local and online model guidance.

## Compute Priority Policy

1. **GPU VRAM first** — all three RTX 4060 GPUs are reserved for AI inference.
   Ollama distributes model layers across available VRAM automatically.
2. **System RAM second** — when VRAM is exhausted, Ollama offloads remaining layers to system RAM.
   The 128 GB RAM ceiling means models up to ~80 GB can run in hybrid GPU+RAM mode.
3. **CPU last** — CPU is used only when GPU and RAM are fully saturated, or for background tasks.
   CPU utilization for AI-related overflow is targeted at no more than 75 % sustained.
   This is enforced through `systemd` CPU quota on the `ollama` service unit.

## Storage Layout

| Mount             | Device    | Contents                              |
|-------------------|-----------|---------------------------------------|
| `/`               | SSD 1     | Ubuntu Server OS, system packages     |
| `/var/lib/ollama` | SSD 2     | Ollama models, Docker volumes         |
| `/var/lib/docker` | SSD 2     | Docker image and container state      |
| `/etc/default`    | SSD 1     | Environment config files (no secrets) |

See `docs/storage-layout.md` for full disk layout details.

## Network Posture

- LAN-only by default.
- Open WebUI listens on `0.0.0.0:3000`.
- Ollama API listens on `127.0.0.1:11434` (not exposed directly to LAN).
- SSH listens on port 22 with key-based auth.
- `ufw` firewall allows only ports 22 and 3000 inbound.
- Optional reverse proxy adds HTTPS and named access; see `docs/network-access.md`.

## External Integrations

- **Proxmox** — Infrastructure agent uses a restricted read/write API token against a separate
  Proxmox host.  See `docs/proxmox-integration.md`.
- **VS Code Remote SSH** — Software Engineering agent workspace is accessible from VS Code on
  a separate developer device.  See `docs/vscode-integration.md`.
- **Online AI providers** — Optional OpenAI, Anthropic, and Google Gemini APIs are routed
  through Open WebUI's external model configuration.  API keys are never stored in this
  repository.  See `docs/online-ai-providers.md`.

## Operating Model

- Ollama runs as a `systemd` service, auto-starts on boot.
- Open WebUI runs as a Docker container managed by a `systemd` wrapper service.
- The Finance agent model is pinned to always-loaded state in Ollama.
- Other agent models are loaded on demand and remain resident while active.
- The Evaluator agent runs on a weekly `systemd` timer triggered by `src/weekly-review.sh`.
- All service state is persistent across reboots.
