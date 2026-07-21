# Local LLM Scripts

This folder contains the complete automation infrastructure for bootstrapping and managing a Local_LLM host.

## Core Installation & Automation

1. **invoke-skippy-usb-automation.ps1** - Master orchestrator: validates environment, generates password hash, and calls the prepare script.
2. **prepare-ubuntu-server-26.04-usb-autoinstall.ps1** - Prepares an Ubuntu Server 26.04 USB with unattended cloud-init install, bundles all Local_LLM artifacts, and configures first-boot automation.
3. **skippy-preseed.cfg** - Ubuntu preseed configuration for fully unattended OS installation (hostname, user, timezone, partitioning).
4. **bootstrap-local-llm-host.sh** - Comprehensive post-install bootstrap: installs Docker, Ollama, applies GPU policy, starts services, and runs validation. Can be run as-is or triggered automatically via first-boot service.

## First-Boot Automation

These files automate the setup immediately after Ubuntu installation completes:

5. **local-llm-first-boot.service** - Systemd service that runs once on first boot after OS install.
6. **local-llm-first-boot-runner.sh** - First-boot orchestrator that coordinates GPU detection, waits for NVIDIA drivers, runs the main bootstrap, handles reboots if needed, and validates completion.

## Helper & Configuration Files

7. **local-llm.env.example** - Environment configuration template (GPU devices, ports, container names, etc.).
8. **apply-ollama-gpu-policy.sh** - Generates Ollama systemd override from the Local_LLM environment file so GPU allocation is enforced.
9. **run-open-webui.sh** - Idempotent Open WebUI container deployment against a local Ollama runtime.
10. **local-llm-open-webui.service** - Systemd service for lifecycle management of the Open WebUI container.

## Health Monitoring & Diagnostics

11. **local-llm-health-check.sh** - Comprehensive health validator: checks Ollama service, endpoints, Open WebUI, GPUs, and disk space. Generates health reports.
12. **local-llm-health-check.service** - Systemd service for running health checks on-demand.
13. **local-llm-health-check.timer** - Systemd timer that runs health checks automatically every 30 minutes (first check at 5 minutes).

## Validation

14. **validate-local-llm.sh** - Service, GPU, and endpoint validation for the Local_LLM host (useful for manual checks or post-bootstrap confirmation).
15. **new-linux-password-hash.ps1** - Windows utility to generate Linux-compatible SHA-512 crypt password hashes for secure password-less cloud-init setup.

## Complete Automation Flow

### Option 1: Fully Unattended (Recommended)
1. Run `invoke-skippy-usb-automation.ps1` on Windows with a password hash
2. Boot Z8 G4 from prepared USB
3. Enter boot-time GRUB parameters: `autoinstall ds=nocloud\;s=/cdrom/nocloud/`
4. Walk away; installation + first-boot bootstrap runs automatically
5. SSH in after ~30 minutes to verify completion

### Option 2: Manual Bootstrap After OS Install
1. Run `invoke-skippy-usb-automation.ps1` to prepare USB (for OS install only)
2. Boot and install Ubuntu Server manually
3. SSH in and run: `sudo /opt/local-llm-src/bootstrap-local-llm-host.sh`

### Option 3: Incremental Setup
1. Install Ubuntu Server manually
2. Copy Local_LLM artifacts to `/opt/local-llm-src/`
3. Run individual components as needed

## Future Extensions

This folder can be extended with:
- Backup and recovery automation
- Model management helpers (auto-download, version pinning)
- Remote health reporting (syslog, webhook notifications)
- Disaster recovery and rollback scripts
- Multi-host orchestration helpers
- Logging aggregation setup
- Performance tuning scripts