# Local Skippy Dedicated Multi-Agent AI Server

## Purpose

This repository now targets a dedicated multi-agent AI server architecture for Ubuntu Server 26.04 using Docker, Ollama, and Open WebUI.

The stack is local-first with optional OpenAI-compatible cloud fallback.

## Confirmed Architecture Decisions

1. OS target: Ubuntu Server 26.04
2. Container runtime: Docker
3. Local LLM runtime: Ollama
4. Main interface for all 4 agents: Open WebUI
5. Isolation model: hybrid (finance prioritized, others share common platform where practical)
6. AI load policy: balanced
7. CPU caps: enforced with systemd and container controls where applicable
8. GPU assignment policy: finance first, others use remaining resources
9. Secrets: root-owned env files under `/etc/local-skippy/`
10. Proxmox scope: read-only plus bounded actions first
11. Evaluator scope: reporting plus pre-approved safe maintenance only
12. Backup defaults: configs, agent definitions, Open WebUI data, reports/logs (exclude large model blobs by default)
13. Network posture: direct LAN first, optional reverse-proxy/HTTPS templates
14. Update posture: automate app-stack updates; do not blindly auto-upgrade sensitive components like GPU drivers

## Start Here

1. `docs/dedicated-server-runbook.md`
2. `docs/automation-and-operations.md`
3. `src/README.md`

## Automation Entry Points

Primary orchestration:

- `src/local-skippy-bootstrap.sh`

Modular scripts:

- `src/local-skippy-preflight.sh`
- `src/local-skippy-init-env.sh`
- `src/local-skippy-agent-scaffold.sh`
- `src/apply-ollama-gpu-policy.sh`
- `src/run-open-webui.sh`
- `src/local-skippy-backup.sh`
- `src/local-skippy-health-report.sh`
- `src/local-skippy-update-stack.sh`
- `src/validate-local-llm.sh`

## Safety Model

All automation follows a stop-and-ask posture for risky or ambiguous operations.

- Use interactive confirmation for potentially disruptive actions.
- Keep destructive behavior opt-in.
- Keep secrets out of Git and in root-only host files.

## VS Code Remote Workflow

Use SSH-based remote development from VS Code to operate and maintain this server.

Practical guidance is in:

- `docs/automation-and-operations.md`

## Legacy Notes

Some earlier mixed-workstation planning documents are still present for historical reference, but this README and the dedicated-server docs are the active source of truth.
