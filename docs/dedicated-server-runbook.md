# Dedicated Server Runbook (Ubuntu Server 26.04)

## Scope

This runbook is the active implementation path for Local Skippy as a dedicated multi-agent AI server.

## Fast Path

1. Install Ubuntu Server 26.04.
2. Install Docker and Ollama.
3. Copy `src/` scripts to `/usr/local/bin` and mark `*.sh` executable.
4. Run `sudo /usr/local/bin/local-skippy-init-env.sh`.
5. Edit `/etc/local-skippy/local-skippy.env` and `/etc/local-skippy/cloud-provider.env`.
6. Run `sudo /usr/local/bin/local-skippy-bootstrap.sh`.
7. Open Open WebUI on `http://<host-ip>:3000`.
8. Validate with `sudo /usr/local/bin/validate-local-llm.sh`.

## Agent Topology (Open WebUI)

All four agents are presented through Open WebUI:

1. Finance (highest priority, always-on, optional cloud fallback)
2. Infrastructure (read-only plus bounded Proxmox actions first)
3. Software Engineering (remote-dev focused)
4. Evaluator (weekly reporting plus pre-approved safe maintenance only)

Scaffold files are generated under `/etc/local-skippy/agents/`.

## Resource Controls

- Ollama control plane:
  - `src/apply-ollama-gpu-policy.sh` writes systemd override with `CUDA_VISIBLE_DEVICES`, `NVIDIA_VISIBLE_DEVICES`, and `CPUQuota`.
- Open WebUI container:
  - `src/run-open-webui.sh` applies container limits (`--cpus`, `--memory`).

Default posture is balanced load with finance-first GPU order.

## Secrets and Cloud Integration

- Store secrets only in root-owned files:
  - `/etc/local-skippy/local-skippy.env`
  - `/etc/local-skippy/cloud-provider.env`
- Cloud integration is optional and local-first.
- Use OpenAI-compatible settings only when escalation is needed.

## Network and Access

- Default access: direct LAN to Open WebUI.
- Optional reverse proxy template: `src/nginx-local-skippy.conf.example`.
- Optional TLS block is provided as commented template content.

## Weekly Evaluator Automation

Use:

- `src/local-skippy-health-report.sh`
- `src/local-skippy-weekly-review.service`
- `src/local-skippy-weekly-review.timer`

Install timer example:

```sh
sudo install -m 644 src/local-skippy-weekly-review.service /etc/systemd/system/local-skippy-weekly-review.service
sudo install -m 644 src/local-skippy-weekly-review.timer /etc/systemd/system/local-skippy-weekly-review.timer
sudo systemctl daemon-reload
sudo systemctl enable --now local-skippy-weekly-review.timer
```

## Stop Rules

Stop and ask for confirmation before:

1. Replacing running containers.
2. Changing GPU assignments.
3. Performing updates on production hours.
4. Expanding evaluator authority beyond safe pre-approved maintenance.
