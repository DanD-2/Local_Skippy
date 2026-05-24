# Start Here

## Purpose

Use this file if you want the shortest path through the Local Skippy project.

If you only read one document before touching the host, read this one first.

## What This Project Is

Local Skippy is a **dedicated headless AI server** running on Ubuntu Server 24.04 LTS.  All
access is through a browser URL or remote tooling — there is no local GUI.

The server hosts four Hermes AI agents, each with a distinct role:

1. **Finance** — financial projects and analysis, browser access via Open WebUI, highest priority.
2. **Infrastructure** — local infrastructure and Proxmox management, constrained credentials.
3. **Software Engineering** — general programming, accessed from VS Code on a separate device.
4. **Evaluator** — weekly server and agent evaluation, proposes and (within policy) enacts improvements.

## Fast Path

1. Read `docs/architecture.md` for the system design.
2. Follow `docs/ubuntu-server-install-runbook.md` to install Ubuntu Server 24.04 LTS.
3. Run `src/install-host.sh` to install all runtime dependencies.
4. Copy `src/skippy.env.example` to `/etc/default/skippy` and fill in values.
5. Run `src/configure-agents.sh` to deploy all four Hermes agents.
6. Run `src/validate-local-llm.sh` to confirm the stack is healthy.
7. Read `docs/operations.md` before making any changes to a running system.

## Deployment Picture

```
flowchart TD
    A[Start Here] --> B[Install Ubuntu Server 24.04 LTS]
    B --> C[Run install-host.sh]
    C --> D[Copy and edit skippy.env.example]
    D --> E[Run configure-agents.sh]
    E --> F[Run validate-local-llm.sh]
    F --> G[Access Open WebUI at http://skippy.aybara.local:3000]
```

## Quick Operator Summary

1. Build a clean Ubuntu Server 24.04 LTS host — no desktop packages.
2. Install the NVIDIA driver and confirm all three GPUs appear in `nvidia-smi`.
3. Install Docker and Ollama.
4. Copy `src/skippy.env.example` to `/etc/default/skippy`.
5. Run `src/install-host.sh` for remaining dependencies.
6. Run `src/configure-agents.sh` to pull models and create agent profiles.
7. Run `src/validate-local-llm.sh` to confirm the full stack is healthy.
8. Open a browser to `http://skippy.aybara.local:3000` from a LAN device.

## Key Browser and Remote Entry Points

| Access point            | URL / method                              |
|-------------------------|-------------------------------------------|
| Open WebUI (all agents) | http://skippy.aybara.local:3000           |
| Ollama API              | http://skippy.aybara.local:11434          |
| SSH admin               | ssh daniel@skippy.aybara.local            |
| VS Code remote (SW Eng) | VS Code → Remote SSH → skippy.aybara.local|

## Stop Rules

Stop and fix the current step before continuing if any of these happen:

1. `nvidia-smi` does not show all three GPUs.
2. Docker or Ollama fails to start cleanly.
3. The environment file at `/etc/default/skippy` is missing or incomplete.
4. Open WebUI is not reachable on `http://skippy.aybara.local:3000` from a LAN device.
5. Any agent model fails to respond to a test prompt.

## What You Can Ignore On The First Pass

Do not start with these until the baseline is running:

1. Online AI provider integration (API keys, external model routing).
2. Reverse proxy or HTTPS configuration.
3. Proxmox integration for the Infrastructure agent.
4. VS Code Remote SSH configuration for the Software Engineering agent.
5. Weekly evaluation schedule for the Evaluator agent.

## Human Summary

The safe operator path is:

1. Install the OS headless.
2. Validate all three GPUs.
3. Install runtime and helpers.
4. Deploy agents.
5. Validate from the LAN.
6. Then add optional integrations one at a time.