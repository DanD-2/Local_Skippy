# Local Skippy Implementation Plan

## Objective

Deploy a dedicated headless AI server on Ubuntu Server 24.04 LTS hosting four Hermes AI agents,
accessible from a browser and VS Code, with full GPU inference capability and optional online AI
provider integration.

## Phase Overview

```
Phase 1 → Host and OS
Phase 2 → Runtime and GPU
Phase 3 → Agent Deployment
Phase 4 → Remote Access
Phase 5 → Operational Hardening
Phase 6 → Optional: Online Providers and Advanced Integration
```

---

## Phase 1: Host and OS

**Goal:** Clean, headless Ubuntu Server 24.04 LTS on the HP Z8 G4.

Steps:

1. Confirm BIOS settings: UEFI, Secure Boot off, all three GPUs visible.
2. Install Ubuntu Server 24.04 LTS (no desktop packages).
3. Set static IP `192.168.128.5`, hostname `skippy`.
4. Partition SSD 1 for OS, SSD 2 for model and Docker data.
5. Install NVIDIA driver 550-server and confirm three GPUs in `nvidia-smi`.
6. Configure `ufw` firewall: allow SSH (22) and Open WebUI (3000) from LAN only.
7. Disable SSH password auth; enable SSH key auth only.

Exit criteria:

- [ ] Three GPUs visible in `nvidia-smi`.
- [ ] SSH key login works.
- [ ] `ufw status` shows correct open ports.

---

## Phase 2: Runtime and GPU

**Goal:** Ollama and Docker running with all three GPUs allocated.

Steps:

1. Install Docker CE and NVIDIA Container Toolkit.
2. Install Ollama and configure the systemd service.
3. Run `src/apply-ollama-gpu-policy.sh` to expose all three GPUs (`0,1,2`).
4. Set `CPUQuota` in the Ollama systemd override for the 75 % CPU policy.
5. Configure `/etc/default/skippy` from `src/skippy.env.example`.
6. Install helper scripts to `/usr/local/bin/`.
7. Pull the Finance agent model first:
   ```bash
   ollama pull nous-hermes2:34b-q4_K_M
   ```

Exit criteria:

- [ ] `ollama run nous-hermes2:34b-q4_K_M ""` returns a response.
- [ ] `ollama ps` shows the model using all three GPUs.
- [ ] CPU quota is confirmed in `systemctl cat ollama`.

---

## Phase 3: Agent Deployment

**Goal:** All four Hermes agents deployed and accessible via Open WebUI.

Steps:

1. Pull all agent models:
   ```bash
   ollama pull nous-hermes2:34b-q4_K_M
   ollama pull nous-hermes2:13b-q4_K_M
   ollama pull nous-hermes2-mixtral:8x7b-q4_K_M
   ```
2. Run `src/configure-agents.sh` to create Open WebUI model profiles for all four agents.
3. Install and enable the Open WebUI systemd service.
4. Deploy Open WebUI with `src/run-open-webui.sh`.
5. Create the Open WebUI admin account (first registration = admin).
6. Create individual user accounts for each human user.
7. Disable public Open WebUI registration.
8. Test each agent with a representative prompt.

Exit criteria:

- [ ] All four agents respond correctly to test prompts in Open WebUI.
- [ ] Finance agent model is always resident (`ollama ps` shows it loaded).
- [ ] `src/validate-local-llm.sh` passes all checks.

---

## Phase 4: Remote Access

**Goal:** VS Code Remote SSH and optional reverse proxy working.

Steps:

1. Verify SSH key access from all developer devices.
2. Configure VS Code Remote SSH and test the connection.
3. Install the Continue extension and configure it to use Ollama.
4. (Optional) Set up a reverse proxy for HTTPS if LAN HTTPS access is needed.
5. Configure Proxmox API token for the Infrastructure agent if the Proxmox host is ready.

Exit criteria:

- [ ] VS Code Remote SSH connects to Skippy and opens a project folder.
- [ ] Continue extension sends a prompt to Ollama and gets a response.
- [ ] (If applicable) Proxmox connection validated with a test API call.

---

## Phase 5: Operational Hardening

**Goal:** All services start on boot, weekly evaluation running, backups defined.

Steps:

1. Confirm all systemd services are enabled and start after reboot.
2. Install and enable the weekly evaluation systemd timer.
3. Run the first manual evaluation: `sudo skippy-weekly-review.sh`.
4. Define and test the Open WebUI data backup procedure.
5. Document the model recovery procedure (pull commands per agent).
6. Review and file the first weekly evaluation report.

Exit criteria:

- [ ] Host reboot: all services come up automatically.
- [ ] Weekly evaluation timer appears in `systemctl list-timers`.
- [ ] First evaluation report written to `/var/log/skippy/`.
- [ ] Backup procedure tested.

---

## Phase 6: Optional Integrations

**Goal:** Online AI providers and advanced integrations enabled where appropriate.

Steps (each is independent and optional):

1. Add OpenAI API key to `/etc/default/skippy` and configure Open WebUI connection.
2. Add Anthropic API key and test with Finance agent for long-document tasks.
3. Configure Google Gemini or Groq as additional model options.
4. Test VS Code Continue with an online provider as a fallback.
5. Enable email or Ntfy notification for the weekly evaluation report.

Exit criteria (per integration):

- [ ] Provider connection test passes in Open WebUI admin settings.
- [ ] Test prompt uses the online model and returns a response.
- [ ] API cost appears in provider dashboard (confirms usage is tracked).

---

## Current Default Decisions

| Decision              | Value                                     |
|-----------------------|-------------------------------------------|
| Host                  | HP Z8 G4                                  |
| OS                    | Ubuntu Server 24.04 LTS                   |
| Runtime               | Ollama                                    |
| Web UI                | Open WebUI                                |
| GPU mode              | All 3 GPUs dedicated to AI (no desktop)   |
| CPU overflow target   | ≤ 75 % sustained                          |
| Network exposure      | LAN-only by default                       |
| Finance agent model   | `nous-hermes2:34b-q4_K_M`                 |
| Infra agent model     | `nous-hermes2:13b-q4_K_M`                 |
| Software Eng model    | `nous-hermes2-mixtral:8x7b-q4_K_M`        |
| Evaluator model       | `nous-hermes2:13b-q4_K_M`                 |