# Local Skippy — Dedicated Ubuntu Server Multi-Agent AI Appliance

## Purpose

Local Skippy is a **dedicated headless AI server** running on Ubuntu Server 24.04 LTS.  It hosts four
role-specific Hermes AI agents backed by local GPU inference, with optional online AI service
integration.  There is no local GUI — all access is through a browser URL or remote tooling.

The hardware target is an HP Z8 G4 with 128 GB RAM and three NVIDIA GeForce RTX 4060 GPUs.  All three
GPUs are dedicated to AI workloads.  Overflow capacity uses system RAM and CPU up to a 75 %
utilization policy target.

## Quick Start

```
ssh daniel@skippy.aybara.local
sudo /usr/local/bin/skippy-validate.sh
```

Browser access after first deployment:

| Service       | URL                                  |
|---------------|--------------------------------------|
| Open WebUI    | http://skippy.aybara.local:3000      |
| Ollama API    | http://skippy.aybara.local:11434     |

## Four Hermes Agents

| Agent               | Role                                      | Access                     | Priority |
|---------------------|-------------------------------------------|----------------------------|----------|
| Finance             | Financial projects and analysis           | Open WebUI browser session | Highest  |
| Infrastructure      | Local infrastructure and Proxmox mgmt     | Open WebUI / SSH tools     | High     |
| Software Engineering| General programming and code review       | VS Code remote / Open WebUI| Normal   |
| Evaluator           | Weekly server and agent evaluation        | Scheduled / Open WebUI     | Low      |

See `docs/agent-topology.md` for full role definitions and model assignments.

## Recommended Reading Order

1. `docs/start-here.md` — fastest operator path
2. `docs/architecture.md` — system design and component roles
3. `docs/agent-topology.md` — four-agent design and model recommendations
4. `docs/ubuntu-server-install-runbook.md` — Ubuntu Server 24.04 install guide
5. `docs/gpu-strategy.md` — GPU-first compute policy and CPU overflow rules
6. `docs/network-access.md` — LAN ports, firewall, and reverse proxy options
7. `docs/security-model.md` — SSH hardening, API key handling, agent boundaries
8. `docs/operations.md` — day-to-day start, stop, update, and backup procedures
9. `docs/online-ai-providers.md` — optional online AI service integration
10. `docs/model-recommendations.md` — local and online model choices per agent
11. `docs/proxmox-integration.md` — Infrastructure agent Proxmox access policy
12. `docs/vscode-integration.md` — VS Code remote access for Software Engineering agent
13. `docs/weekly-evaluation.md` — Evaluator agent workflow and approval policy
14. `docs/implementation-plan.md` — phased rollout checklist

## Scope

This project covers:

1. Dedicated Ubuntu Server 24.04 LTS deployment with no local GUI.
2. Four Hermes AI agent definitions, model assignments, and operational policies.
3. Full-GPU inference with RAM and CPU overflow up to 75 % utilization.
4. Open WebUI browser access for human-facing agents.
5. VS Code remote access for the Software Engineering agent.
6. Proxmox API integration for the Infrastructure agent (constrained credentials).
7. Optional online AI service integration with secure API key handling.
8. Weekly automated evaluation and controlled improvement workflow.
9. LAN-first network posture with optional reverse proxy for HTTPS.

This project does not cover public internet exposure of agents, multi-node clustering, or
fine-tuning workflows.

## Host Identity

| Field          | Value                        |
|----------------|------------------------------|
| Hostname       | `skippy.aybara.local`        |
| IP address     | `192.168.128.5`              |
| OS             | Ubuntu Server 24.04 LTS      |
| Admin user     | `daniel`                     |
| RAM            | 128 GB                       |
| GPUs           | 3 × NVIDIA GeForce RTX 4060  |
| SSDs           | 2 × HP SSD FX900 Pro M.2 1 TB|
| Admin access   | SSH only                     |

## Repository Layout

```
README.md                    — this file
docs/
  start-here.md              — fastest entry point for operators
  architecture.md            — dedicated server system design
  agent-topology.md          — four Hermes agents, models, and access patterns
  agent-policies.md          — operational policies for each agent
  network-access.md          — ports, firewall, and reverse proxy
  security-model.md          — SSH, firewall, API key, and agent boundaries
  operations.md              — start/stop/update/backup runbooks
  ubuntu-server-install-runbook.md — Ubuntu Server 24.04 install guide
  gpu-strategy.md            — GPU-first with RAM/CPU overflow policy
  online-ai-providers.md     — optional online AI provider integration
  model-recommendations.md   — local and online model choices per agent
  proxmox-integration.md     — Infrastructure agent Proxmox access
  vscode-integration.md      — VS Code remote for Software Engineering agent
  weekly-evaluation.md       — Evaluator agent schedule and policy
  implementation-plan.md     — phased rollout plan
  storage-layout.md          — disk layout (preserved from prior version)
  environment-inventory.md   — hardware and dependency inventory
  architecture-options.md    — runtime option analysis (historical reference)
  archive/                   — archived workstation-era documentation
src/
  README.md                  — script inventory
  skippy.env.example         — host environment template
  install-host.sh            — Ubuntu Server bootstrap installer
  configure-agents.sh        — deploy and configure all four Hermes agents
  apply-ollama-gpu-policy.sh — write Ollama systemd GPU override
  run-open-webui.sh          — idempotent Open WebUI container deployment
  validate-local-llm.sh      — post-change validation script
  weekly-review.sh           — Evaluator agent weekly review runner
  local-llm-open-webui.service — systemd unit for Open WebUI container
config/
  agents/
    finance.yaml             — Finance agent model and system-prompt config
    infrastructure.yaml      — Infrastructure agent config
    software-engineering.yaml— Software Engineering agent config
    evaluator.yaml           — Evaluator agent config
```

## Dependencies

1. Ubuntu Server 24.04 LTS on the target HP Z8 G4.
2. NVIDIA driver 550+ and CUDA toolkit for RTX 4060 acceleration.
3. Docker for Open WebUI container management.
4. Ollama for local model serving.
5. Optional online AI provider API keys stored outside the repository.
6. Optional Proxmox API token for Infrastructure agent (restricted, documented separately).
7. Optional reverse proxy for HTTPS named access on the LAN.
