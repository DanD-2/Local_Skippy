# Automation and Operations Guide

## Script Inventory

Top-level orchestrator:

- `src/local-skippy-bootstrap.sh`

Modular scripts:

1. `src/local-skippy-preflight.sh`
2. `src/local-skippy-init-env.sh`
3. `src/local-skippy-agent-scaffold.sh`
4. `src/apply-ollama-gpu-policy.sh`
5. `src/run-open-webui.sh`
6. `src/local-skippy-backup.sh`
7. `src/local-skippy-health-report.sh`
8. `src/local-skippy-update-stack.sh`
9. `src/validate-local-llm.sh`

## Host Preparation Example

```sh
sudo install -m 755 src/*.sh /usr/local/bin/
sudo /usr/local/bin/local-skippy-preflight.sh
sudo /usr/local/bin/local-skippy-init-env.sh
sudo nano /etc/local-skippy/local-skippy.env
sudo nano /etc/local-skippy/cloud-provider.env
sudo /usr/local/bin/local-skippy-bootstrap.sh
```

## Backup Defaults

`src/local-skippy-backup.sh` includes by default:

1. `/etc/local-skippy`
2. `/etc/systemd/system/ollama.service.d`
3. Open WebUI data volume
4. `/var/log/local-skippy`

Large Ollama model blobs are excluded by default.

## Update Strategy

`src/local-skippy-update-stack.sh` is intentionally conservative:

- refreshes Open WebUI image
- restarts app services
- avoids blind GPU driver upgrades

## Monitoring and Weekly Review

`src/local-skippy-health-report.sh` produces lightweight markdown reports with:

- service state
- endpoint checks
- resource snapshot
- evaluator safety notes

For weekly cadence, install the included systemd timer template.

## VS Code Remote Workflow

Recommended setup:

1. Use VS Code Remote SSH to connect to the Ubuntu server.
2. Start from `src/vscode-remote-ssh-config.example` for a clean SSH host profile.
3. Keep repository edits in Git; keep secrets only in `/etc/local-skippy/`.
4. Use terminal tasks to run:
   - preflight
   - validation
   - backup
   - health reports
5. Keep Proxmox operations read-mostly and bounded unless explicitly approved.

## Proxmox and Safety Boundaries

- Infrastructure automation starts from read-only checks.
- Bounded maintenance actions require explicit operator intent.
- Any ambiguous/destructive action should stop and request human confirmation.
