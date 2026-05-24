# Agent Policies

## Purpose

This document defines the trust boundaries, automation limits, and logging requirements for each of the four Hermes agents on the Local Skippy appliance.

## Core Principles

1. Each agent is bounded to its defined role and tool scope.
2. No agent may take destructive or irreversible actions without explicit operator approval.
3. Credentials and API keys are never stored in model context or prompt history.
4. All agent actions touching external systems must be logged.
5. The Evaluator agent proposes changes — it never enacts them autonomously.

## Finance Agent Policy

### Trust Level

High — this agent handles sensitive financial content.

### Permitted Actions

1. Conversational financial analysis within a session.
2. Generating financial models, projections, and summaries.
3. Accessing documents or data explicitly provided by the operator.

### Prohibited Actions

1. Storing sensitive financial data outside the session context.
2. Making API calls to external services unless explicitly configured and approved.
3. Accessing other agents' sessions or data.

### Security Notes

1. Do not paste credentials, account numbers, or passwords into the Finance agent prompt.
2. Treat the model's session context as ephemeral — do not rely on it for persistent storage.
3. Use the Finance agent for analysis and planning, not as a database.

### Uptime Requirement

The Finance agent must be available continuously. Operator should confirm it restarts cleanly after any host maintenance.

---

## Infrastructure Agent Policy

### Trust Level

Elevated — this agent has controlled access to the Proxmox host.

### Permitted Actions

1. Infrastructure planning and documentation generation.
2. Proxmox API operations within the scope of the assigned restricted token.
3. Docker and service configuration advice and command generation.
4. Ubuntu Server administration guidance.

### Prohibited Actions

1. Executing system commands directly on the Skippy host without operator review.
2. Using Proxmox credentials beyond the scope of the restricted API token.
3. Connecting to any systems not explicitly in the approved scope.
4. Storing Proxmox credentials, SSH keys, or tokens in the conversation context.

### Credential Policy

1. Proxmox access uses a dedicated restricted API token — see `docs/proxmox-integration.md`.
2. The token is stored in `/etc/default/local-llm` or a separate secrets file, never in this repository.
3. All infrastructure agent Proxmox operations should be reviewed before execution.

### Logging

All Proxmox API calls made under Infrastructure agent guidance should be logged in the Proxmox audit log.

---

## Software Engineering Agent Policy

### Trust Level

Standard — scoped to development workspaces.

### Permitted Actions

1. Code generation, review, and debugging in any project workspace.
2. Architectural advice and documentation.
3. Test generation.
4. VS Code remote SSH session from a development machine.

### Prohibited Actions

1. Direct write access to production service configurations on the Skippy host.
2. Accessing other agents' sessions or data.
3. Storing repository secrets, API keys, or credentials in conversation context.

### Workspace Notes

1. Project workspaces are on the development machine, not on the Skippy host, unless explicitly set up otherwise.
2. VS Code remote SSH connects to the Skippy host but does not grant broader host admin access.

---

## Evaluator Agent Policy

### Trust Level

Low — read-only analysis and proposals.

### Permitted Actions

1. Reviewing Ollama service logs, resource utilization data, and usage metrics provided by the operator.
2. Generating structured weekly evaluation reports.
3. Proposing improvements to agent configurations, model choices, and resource policies.
4. Summarizing failures, anomalies, and underutilized capacity.

### Prohibited Actions

1. Executing any system commands.
2. Making changes to service configurations, model files, or host settings.
3. Accessing credentials, API tokens, or secrets.
4. Automatically enacting any proposed improvement without operator review and explicit approval.

### Evaluation Scope

The Evaluator may review and propose improvements to:

1. Ollama model selection and sizing.
2. Resource allocation and GPU policy.
3. Agent system prompts and configurations.
4. Host health and service reliability.
5. Open WebUI usage patterns.

The Evaluator must **not** automatically apply changes to any of these areas.

### Report Format

Weekly evaluation reports should follow the format in `docs/weekly-evaluation.md`.

---

## General Automation Boundary

No agent on this appliance has autonomous permission to:

1. Modify its own system prompt or model configuration.
2. Access another agent's sessions.
3. Connect to external systems outside its defined scope.
4. Store credentials or secrets in conversation context.
5. Enact infrastructure or service changes without operator confirmation.

If an agent generates a change proposal, the operator reviews and executes it manually or explicitly approves automated execution within a pre-defined safe list.
