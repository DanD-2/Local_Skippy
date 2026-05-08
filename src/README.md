# Local LLM Scripts

This folder now contains:

1. `validate-local-llm.sh` for service, GPU, and endpoint validation on the Local_LLM host.
2. `run-open-webui.sh` for idempotent Open WebUI container deployment against a local Ollama runtime.
3. `apply-ollama-gpu-policy.sh` for generating an Ollama systemd override from the Local_LLM environment file.
4. `local-llm-open-webui.service` for systemd-based lifecycle management of the Open WebUI container wrapper.
5. `local-llm.env.example` for the host environment settings used by the Local_LLM helper scripts and service files.

Future additions can extend this folder with backup helpers, health monitors, or model-management automation.