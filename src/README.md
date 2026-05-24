# Local Skippy Automation Scripts

This folder contains practical automation for the dedicated Ubuntu Server 26.04 multi-agent stack:

1. `local-skippy-bootstrap.sh` top-level orchestration entry point.
2. `local-skippy-preflight.sh` host validation checks.
3. `local-skippy-init-env.sh` root-owned env initialization under `/etc/local-skippy/`.
4. `local-skippy-agent-scaffold.sh` 4-agent policy/profile scaffolding.
5. `local-skippy-backup.sh` default backup automation (configs, agent definitions, Open WebUI data, logs/reports).
6. `local-skippy-health-report.sh` health dashboard/report generator for weekly review automation.
7. `local-skippy-update-stack.sh` safe app-stack updates (no blind GPU driver upgrades).
8. `run-open-webui.sh` Open WebUI deployment helper with container CPU/memory controls and optional cloud env-file support.
9. `apply-ollama-gpu-policy.sh` Ollama systemd GPU and CPU quota enforcement helper.
10. `validate-local-llm.sh` local runtime and endpoint validation.
11. `local-skippy.env.example` and `cloud-provider.env.example` starter env files.
12. `nginx-local-skippy.conf.example` optional reverse-proxy/HTTPS template.
13. `local-skippy-weekly-review.service` and `.timer` templates for weekly evaluator reports.
14. `vscode-remote-ssh-config.example` remote-dev-friendly SSH template for VS Code workflows.

Legacy Local_LLM files remain for compatibility, but `/etc/local-skippy/` is now the primary configuration root.