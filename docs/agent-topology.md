# Agent Topology — Four Hermes Agents

## Overview

Local Skippy runs four role-specific Hermes-family AI agents.  Each agent is implemented as an
Open WebUI model workspace backed by a dedicated Ollama model.  Agents are isolated by system
prompt, model assignment, and resource priority.

The Hermes family (NousResearch) is chosen for its strong instruction-following, tool-use
capability, and practical reasoning across all four roles.

## Agent 1 — Finance

| Field             | Value                                          |
|-------------------|------------------------------------------------|
| Name              | Finance                                        |
| Role              | Financial projects, analysis, and planning     |
| Priority          | **Highest** — always-on, restart-on-failure    |
| Local model       | `nous-hermes2:34b-q4_K_M`                      |
| Online alternative| OpenAI `gpt-4o` or Anthropic `claude-3-5-sonnet`|
| Access path       | Open WebUI browser session                     |
| Uptime target     | Continuous — model pinned resident in Ollama   |

### Responsibilities

- Financial project planning, budgeting, and cost analysis.
- Data interpretation from financial documents.
- Scenario modelling and forecasting.
- Investment research and portfolio analysis.
- Natural-language summarization of financial reports.

### Resource Policy

- The Finance agent model is always loaded and never evicted from VRAM.
- Other agents compete for remaining GPU and RAM capacity.
- If VRAM is insufficient for all active models, lower-priority agent models are evicted first.

### Configuration reference

`config/agents/finance.yaml`

---

## Agent 2 — Infrastructure

| Field             | Value                                           |
|-------------------|-------------------------------------------------|
| Name              | Infrastructure                                  |
| Role              | Local infrastructure setup and maintenance      |
| Priority          | High                                            |
| Local model       | `nous-hermes2:13b-q4_K_M`                       |
| Online alternative| OpenAI `gpt-4o-mini` or Anthropic `claude-3-haiku`|
| Access path       | Open WebUI browser session                      |
| Proxmox access    | Restricted API token (see proxmox-integration.md)|

### Responsibilities

- Assisting with server configuration, package management, and service deployment.
- Generating and reviewing infrastructure-as-code (Ansible, shell scripts, systemd units).
- Proxmox hypervisor management on the separate dedicated Proxmox device.
- Documenting and reviewing network, firewall, and storage configurations.
- Diagnosing service failures and proposing remediation steps.

### Access Boundaries

- Has read/write access to the Proxmox API via a scoped token stored in `/etc/default/skippy`.
  The token grants only the minimum required Proxmox privileges.
- Does **not** have the ability to execute arbitrary shell commands on the Skippy host itself
  without operator involvement.
- All Proxmox actions should be logged.  See `docs/proxmox-integration.md`.

### Configuration reference

`config/agents/infrastructure.yaml`

---

## Agent 3 — Software Engineering

| Field             | Value                                            |
|-------------------|--------------------------------------------------|
| Name              | SoftwareEng                                      |
| Role              | General-purpose software programming             |
| Priority          | Normal                                           |
| Local model       | `nous-hermes2-mixtral:8x7b-q4_K_M`               |
| Online alternative| OpenAI `gpt-4o` or `claude-3-5-sonnet`           |
| Access path       | Open WebUI browser session + VS Code Remote SSH  |

### Responsibilities

- Code generation, review, and refactoring in any language.
- Debugging, testing strategy, and documentation.
- Architecture advice and design pattern recommendations.
- Script authoring (bash, Python, PowerShell, etc.).
- Answering programming questions and explaining technical concepts.

### VS Code Integration

The Software Engineering agent is the primary agent for VS Code-based workflows.

A developer on a separate device connects to the Skippy host via VS Code Remote SSH, then
interacts with the agent through:

- The VS Code Continue extension pointed at `http://skippy.aybara.local:11434` (Ollama).
- Open WebUI in a browser tab for conversational assistance.

See `docs/vscode-integration.md` for full VS Code configuration steps.

### Configuration reference

`config/agents/software-engineering.yaml`

---

## Agent 4 — Evaluator

| Field             | Value                                            |
|-------------------|--------------------------------------------------|
| Name              | Evaluator                                        |
| Role              | Weekly server and agent evaluation               |
| Priority          | Low                                              |
| Local model       | `nous-hermes2:13b-q4_K_M`                        |
| Online alternative| OpenAI `gpt-4o-mini`                             |
| Access path       | Open WebUI browser session + weekly systemd timer|
| Schedule          | Weekly (Sunday 02:00 local time by default)      |

### Responsibilities

- Reviewing Ollama and Docker service logs for errors and anomalies.
- Measuring GPU, RAM, and CPU utilization trends.
- Assessing agent usage and response quality from stored conversation metadata.
- Identifying model update opportunities (newer Hermes releases, quantization improvements).
- Proposing configuration and policy improvements.
- Generating a weekly markdown evaluation report stored under `/var/log/skippy/`.

### Approval Policy

The Evaluator agent operates within explicit boundaries:

**Safe-to-enact automatically (no approval required):**
- Updating Ollama models to newer versions of the same model family.
- Rotating log files.
- Pulling pre-approved model variants already listed in `config/agents/evaluator.yaml`.

**Requires operator approval before enacting:**
- Changing which model a different agent uses.
- Modifying systemd service configurations.
- Any network or firewall changes.
- Any Proxmox operations.
- Adding new external AI provider integrations.
- Any change that affects the Finance agent's uptime or priority.

See `docs/weekly-evaluation.md` for the full evaluation workflow.

### Configuration reference

`config/agents/evaluator.yaml`

---

## Multi-Agent Resource Sharing

All four agents share the same Ollama runtime and GPU pool.  Priority is enforced through:

1. **Model residency** — Finance agent model is always resident; others load on demand.
2. **Ollama request queuing** — concurrent requests are queued by Ollama; Finance requests are
   served from its always-loaded model instance without waiting for load time.
3. **CPU quota** — the `ollama.service` systemd unit has a CPU quota that enforces the 75 %
   utilization policy target for AI overflow onto CPU.

When all three GPUs and system RAM are saturated, lower-priority inference requests wait in
Ollama's queue until capacity is available.  The Finance agent is insulated from this by its
always-resident model policy.
