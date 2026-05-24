# Local Skippy Scripts

This folder contains helper scripts and service files for the Local Skippy dedicated AI server.

## Scripts

| Script                      | Purpose                                                         |
|-----------------------------|-----------------------------------------------------------------|
| `install-host.sh`           | Bootstrap install: Docker, NVIDIA toolkit, Ollama, all helpers  |
| `configure-agents.sh`       | Pull all agent models and deploy Open WebUI                     |
| `apply-ollama-gpu-policy.sh`| Write Ollama systemd GPU and CPU quota override                 |
| `run-open-webui.sh`         | Idempotent Open WebUI container deployment                      |
| `validate-local-llm.sh`     | Full stack validation (services, GPUs, models, endpoints)       |
| `weekly-review.sh`          | Evaluator agent weekly health review and report                 |

## Service File

| File                             | Purpose                                         |
|----------------------------------|-------------------------------------------------|
| `local-llm-open-webui.service`   | systemd unit managing the Open WebUI container  |

## Environment Template

| File                  | Purpose                                               |
|-----------------------|-------------------------------------------------------|
| `skippy.env.example`  | Template for `/etc/default/skippy` — copy and edit    |

## Install Order

```
1. sudo src/install-host.sh          # installs deps, copies scripts
2. sudo nano /etc/default/skippy     # fill in GPU count, API keys, etc.
3. sudo skippy-configure-agents.sh   # pull models, deploy Open WebUI
4. sudo skippy-validate.sh           # confirm everything is healthy
```

## Installed Script Locations

After running `install-host.sh`, the scripts are available at:

| Script                         | Installed path                              |
|--------------------------------|---------------------------------------------|
| `apply-ollama-gpu-policy.sh`   | `/usr/local/bin/skippy-apply-gpu-policy.sh` |
| `run-open-webui.sh`            | `/usr/local/bin/local-llm-run-open-webui.sh`|
| `validate-local-llm.sh`        | `/usr/local/bin/skippy-validate.sh`         |
| `weekly-review.sh`             | `/usr/local/bin/skippy-weekly-review.sh`    |
| `configure-agents.sh`          | `/usr/local/bin/skippy-configure-agents.sh` |

Future additions can extend this folder with additional backup helpers or model-management
automation.  All additions must follow the no-secrets-in-repo rule and read sensitive values
from `/etc/default/skippy` at runtime.