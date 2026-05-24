# Local Skippy — Dedicated Multi-Agent AI Appliance

## Purpose

This project defines and operates a **dedicated Ubuntu Server AI appliance** on the HP Z8 G4 host.

The machine runs four always-available Hermes AI agents, each with a distinct role, served through Open WebUI. Access is browser-based and SSH-only. No desktop environment is installed or required.

## Start Here

If you are building or operating the host, start with `docs/start-here.md`.

Recommended reading order:

1. `docs/start-here.md` — shortest operator path
2. `docs/agent-topology.md` — what the four agents are and which models they use
3. `docs/ubuntu-24.04-install-runbook.md` — how to build the server
4. `docs/gpu-strategy.md` — GPU-first AI resource policy
5. `docs/storage-layout.md` — disk layout for a headless server
6. `docs/security-model.md` — SSH, firewall, and access boundaries
7. `docs/operations.md` — day-to-day start, stop, update, and backup
8. `docs/cloud-ai-integration.md` — optional online AI service access

## Project Description

### Host

- **Hardware:** HP Z8 G4 workstation
- **OS:** Ubuntu Server 24.04 LTS (headless, no GUI)
- **Hostname:** `Skippy` / `192.168.128.5`
- **Admin:** SSH only

### The Four Agents

| Agent | Role | Priority |
|---|---|---|
| Finance | Financial projects and analysis | Highest — always on |
| Infrastructure | Local infrastructure and Proxmox management | High |
| Software Engineering | General programming, VS Code remote integration | Standard |
| Evaluator | Weekly server and agent evaluation, improvement proposals | Scheduled |

See `docs/agent-topology.md` for model assignments, resource policies, and access paths.
See `docs/agent-policies.md` for trust boundaries and automation limits.

### Resource Policy

1. All three RTX 4060 GPUs are allocated to AI inference by default.
2. GPU VRAM is consumed first; RAM overflow is used next when needed.
3. CPU inference load is capped at approximately 75% to preserve host stability.
4. The Finance agent holds the highest scheduling priority.

See `docs/gpu-strategy.md` for the full GPU and resource policy.

### Access Model

- End users: browser via `http://skippy` or `http://192.168.128.5:3000`
- Admin: SSH from LAN
- VS Code remote: SSH to the host, project workspace on the host
- No public internet exposure by default

### Cloud AI Integration

Optional cloud AI provider access can be enabled for any agent that needs it.
See `docs/cloud-ai-integration.md`.

## Project Files

### Documentation

| File | Purpose |
|---|---|
| `docs/start-here.md` | Operator entry point and fast path |
| `docs/agent-topology.md` | Four-agent architecture, model assignments, access paths |
| `docs/agent-policies.md` | Per-agent trust, automation, and logging boundaries |
| `docs/implementation-plan.md` | Phased rollout plan |
| `docs/ubuntu-24.04-install-runbook.md` | Ubuntu Server install and service setup |
| `docs/gpu-strategy.md` | GPU-first resource policy and configuration |
| `docs/storage-layout.md` | Disk layout for headless server operation |
| `docs/environment-inventory.md` | Host, hardware, and network assumptions |
| `docs/architecture-options.md` | Runtime and stack decisions |
| `docs/security-model.md` | SSH hardening, firewall, and access control |
| `docs/operations.md` | Start, stop, update, backup, and recovery |
| `docs/weekly-evaluation.md` | Evaluator agent workflow and reporting |
| `docs/proxmox-integration.md` | Infrastructure agent Proxmox access policy |
| `docs/cloud-ai-integration.md` | Optional online AI service integration |

### Configuration

| File | Purpose |
|---|---|
| `config/agents/finance.yaml` | Finance agent system profile |
| `config/agents/infrastructure.yaml` | Infrastructure agent system profile |
| `config/agents/software-engineering.yaml` | Software engineering agent system profile |
| `config/agents/evaluator.yaml` | Evaluator agent system profile |

### Scripts and Services

| File | Purpose |
|---|---|
| `src/local-llm.env.example` | Host environment template |
| `src/apply-ollama-gpu-policy.sh` | Write Ollama systemd GPU override from env file |
| `src/run-open-webui.sh` | Deploy or redeploy the Open WebUI container |
| `src/local-llm-open-webui.service` | systemd unit for Open WebUI lifecycle |
| `src/validate-local-llm.sh` | Post-change validation: GPU, Ollama, WebUI, Docker |

### Archive

Legacy workstation and creative-tool documentation has been moved to `archive/`.
See `archive/README.md` for the list of archived files.

## Dependencies

1. Ubuntu Server 24.04 LTS on bare metal.
2. NVIDIA drivers and CUDA from the Ubuntu package path.
3. Docker Engine for Open WebUI container management.
4. Ollama for local model serving.
5. Optional cloud AI provider API keys managed through env files — never committed to this repository.
