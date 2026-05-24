# Agent Policies — Operational Boundaries and Rules

## Purpose

This document defines the operational policies that govern each agent's behaviour, resource
access, and automation boundaries.  Any change to agent capabilities must also update this
document.

## Finance Agent Policy

### Priority

The Finance agent runs at the highest inference priority on Skippy.  Its model is always loaded
and never evicted.  If a system event forces an unload, the Finance agent model is restored
before any other agent.

### Uptime

The Finance agent should be continuously available.  The Open WebUI and Ollama services include
restart-on-failure configuration.  Any planned maintenance that would interrupt Finance agent
availability must be communicated in advance and kept as brief as possible.

### Data Handling

- Financial conversation data is stored in the Open WebUI database volume (`open-webui` Docker
  volume on SSD 2).
- Conversation history is retained for reference.
- No financial data, account numbers, or credentials should be pasted into the chat interface.
  The agent is a reasoning tool, not a secure financial data store.

### Access Control

- Finance agent workspace is accessible to authenticated Open WebUI users.
- The operator controls Open WebUI user accounts.
- No external network access for the Finance agent.

---

## Infrastructure Agent Policy

### Scope

The Infrastructure agent is limited to:

- Advising on and generating configuration for the Skippy host itself.
- Managing the dedicated Proxmox device via its restricted API token.
- Documenting and reviewing network, storage, and service configuration.

### Proxmox Access

- The agent uses a Proxmox API token stored in `/etc/default/skippy` (env var
  `SKIPPY_PROXMOX_TOKEN`).
- The token is scoped to the minimum required Proxmox privileges.
- The token is not committed to this repository at any time.
- All Proxmox API calls performed through the agent should be logged.
- The agent may read VM/container status and manage free-tier Proxmox services.
- The agent may not delete production VMs without explicit operator confirmation.

### Execution Boundary

The Infrastructure agent does not have direct shell execution on the Skippy host.  It generates
scripts and commands for operator review and execution.  The operator decides whether to run
generated scripts.

---

## Software Engineering Agent Policy

### Scope

The Software Engineering agent provides general coding assistance with no special system
privileges.

### Workspace

- The VS Code Remote SSH workspace is the operator's own home directory on Skippy.
- The agent has no broader host access than the SSH user.
- The agent should not be given access to `/etc/default/skippy` or any credential files.

### Code Execution

The agent does not execute code autonomously.  It generates code for human review and execution.

---

## Evaluator Agent Policy

### Schedule

The Evaluator agent runs weekly via a systemd timer (default: Sunday 02:00 local time).  The
operator can also trigger a manual evaluation run with `src/weekly-review.sh`.

### Data Sources

The Evaluator agent reviews:

- Systemd journal output for `ollama.service` and `local-llm-open-webui.service`.
- `nvidia-smi` utilization snapshots.
- `/var/log/skippy/` evaluation history.
- Open WebUI conversation count metadata (not conversation content).

### Automation Boundaries

The Evaluator agent may autonomously enact **only** the following:

- `ollama pull <same-family-model>` to update a model to a newer version in the same family.
- Log rotation via `logrotate`.
- Writing the weekly evaluation report to `/var/log/skippy/`.

All other proposed improvements must be written to the weekly report and require operator
review before implementation.

### Report Format

The weekly evaluation report is a markdown file saved as:
`/var/log/skippy/evaluation-YYYY-MM-DD.md`

Minimum required sections:

1. Summary (one paragraph).
2. GPU / RAM / CPU utilization trends.
3. Service health events since the last evaluation.
4. Agent usage summary.
5. Proposed improvements (with approval-required flag where applicable).
6. Actions enacted automatically (if any).

---

## Shared Policies

### No Plaintext Secrets

- API keys, Proxmox tokens, and credentials must never be committed to this repository.
- All secrets are stored in `/etc/default/skippy` with file permissions `640` owned by
  `root:ollama`.
- The `src/skippy.env.example` file contains only placeholder values, never real secrets.

### LAN-First Posture

- All agent endpoints are LAN-only by default.
- No agent endpoint is exposed to the internet without an explicit operator decision.
- Any internet exposure requires a separate reverse proxy with TLS and documented justification.

### Audit Trail

- Significant agent interactions that affect host configuration should be logged to
  `/var/log/skippy/agent-actions.log`.
- The Evaluator agent reviews this log as part of the weekly cycle.
