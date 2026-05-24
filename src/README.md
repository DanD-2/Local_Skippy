# Local Skippy Scripts

This folder contains host-side helper scripts and service files for the Local Skippy AI appliance.

## Files

1. `validate-local-llm.sh` — service, GPU, and endpoint validation; run after any service change.
2. `run-open-webui.sh` — idempotent Open WebUI container deployment against a local Ollama runtime.
3. `apply-ollama-gpu-policy.sh` — write an Ollama systemd override from the environment file to expose all GPUs.
4. `local-llm-open-webui.service` — systemd unit for Open WebUI container lifecycle management.
5. `local-llm.env.example` — template for `/etc/default/local-llm`; copy and populate before first use.

## Deployment Notes

1. Copy `local-llm.env.example` to `/etc/default/local-llm` and set `chmod 600`.
2. Set `LOCAL_LLM_GPU_DEVICES=0,1,2` to allocate all three GPUs to inference.
3. Install `apply-ollama-gpu-policy.sh` to `/usr/local/bin/` and run it to write the Ollama systemd override.
4. Install `run-open-webui.sh` to `/usr/local/bin/local-llm-run-open-webui.sh`.
5. Install `local-llm-open-webui.service` to `/etc/systemd/system/` and enable it.
6. Run `validate-local-llm.sh` after install and after any service change to confirm the stack is healthy.

See `docs/ubuntu-24.04-install-runbook.md` for the full installation sequence.