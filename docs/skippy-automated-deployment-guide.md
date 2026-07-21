# Skippy Automated Deployment Guide

## Overview

The Local_LLM project now includes **deep automation** for the entire Skippy deployment from bare metal to fully operational LLM server. This guide covers the fully automated path.

## Automation Capabilities

### What Runs Automatically

1. **OS Installation** - Ubuntu Server 26.04 LTS with all defaults pre-configured
2. **First-Boot Setup** - After OS reboots, systemd automatically runs Local_LLM initialization
3. **NVIDIA Driver Detection** - Waits intelligently for NVIDIA drivers, retries if needed
4. **Ollama & Docker Setup** - Complete infrastructure installation
5. **GPU Policy Application** - All 3 GPUs dedicated to LLM inference
6. **Open WebUI Deployment** - Browser interface starts automatically
7. **Health Monitoring** - Periodic checks every 30 minutes
8. **Model Pre-Staging** - Optional first model pulled during bootstrap

### User Intervention Points

- **Before boot**: Generate Linux password hash (Windows PowerShell)
- **During boot**: Enter GRUB autoinstall parameter
- **After ~30 minutes**: SSH in to verify completion

## Step-by-Step Deployment

### Phase 1: USB Preparation (Windows)

**Objective:** Create a bootable USB with unattended install + Local_LLM automation

**Prerequisites:**
- Ubuntu Server 26.04 LTS installer on USB (drive D:)
- PowerShell 5+ on Windows
- Access to Local_LLM repository

**Steps:**

```powershell
# From the Local_LLM repository root
cd src

# Generate a secure Linux password hash
$hash = & .\new-linux-password-hash.ps1
# (Will prompt for password interactively; never shows on screen)

# Prepare the USB with full automation
.\invoke-skippy-usb-automation.ps1 `
  -UsbDriveLetter D `
  -Hostname Skippy `
  -AdminUsername daniel `
  -LinuxPasswordHash $hash `
  -StaticAddressCidr "192.168.128.5/24" `
  -Gateway "192.168.128.1" `
  -NameServers @("192.168.128.1", "1.1.1.1") `
  -SkipConfirmation:$false
```

**What it does:**
- Validates USB is an Ubuntu Server installer
- Creates cloud-init configuration files
- Bundles all Local_LLM automation artifacts to `/nocloud/local-llm-src`
- Shows you a preflight checklist
- Ejects the USB safely

**Output:**
```
Skippy USB install preflight checklist
1. USB drive detected: D:
2. Ubuntu installer media structure detected (casper folder exists).
3. Identity defaults: hostname=Skippy username=daniel
4. Network mode: static (192.168.128.5/24, gateway 192.168.128.1, DNS 192.168.128.1, 1.1.1.1)
5. Local_LLM automation payload will be copied to /cdrom/nocloud/local-llm-src.

Boot instructions:
1. Boot the Z8 G4 from this USB drive.
2. At the GRUB menu, edit the linux line and append:
   autoinstall ds=nocloud\;s=/cdrom/nocloud/
3. Continue boot; installer will run unattended with cloud-init.
```

### Phase 2: Automated OS Installation

**Objective:** Boot Z8 G4 and let Ubuntu + cloud-init install everything

**Steps:**

1. **Power on Z8 G4** with prepared USB in USB port
2. **Enter BIOS/UEFI** (usually F10 or F12 at boot)
   - Confirm USB is in boot order
   - Save and exit
3. **Boot from USB**
4. **At GRUB menu**, when you see the Ubuntu boot prompt:
   - Press `e` to edit the linux boot line
   - Navigate to the end of the line
   - Append: `autoinstall ds=nocloud\;s=/cdrom/nocloud/`
   - Press `Ctrl+X` or `F10` to boot
5. **Walk away** - Ubuntu will install completely unattended
   - Watch the progress on screen (optional)
   - Takes ~10-15 minutes for OS installation

**What happens automatically:**
```
[INSTALLER] Partitioning disk
[INSTALLER] Installing base packages
[INSTALLER] Configuring bootloader
[INSTALLER] First boot in 60 seconds...
[REBOOT]
[CLOUD-INIT] Running late-commands
[CLOUD-INIT] Copying Local_LLM artifacts to /opt/local-llm-src
[CLOUD-INIT] Installing first-boot service
[CLOUD-INIT] Enabling local-llm-first-boot.service
[REBOOT]
```

### Phase 3: First-Boot Automation

**Objective:** Automatic bootstrap of Docker, Ollama, and Local_LLM stack

**What happens (no user action required):**

```
[SYSTEMD] local-llm-first-boot.service activates
[RUNNER] Waiting for GPU detection...
[RUNNER] Executing bootstrap-local-llm-host.sh
  [BOOTSTRAP] Installing Docker
  [BOOTSTRAP] Installing NVIDIA drivers (if needed)
  [BOOTSTRAP] Installing Ollama
  [BOOTSTRAP] Copying Local_LLM configuration
  [BOOTSTRAP] Applying GPU policy (all 3 GPUs)
  [BOOTSTRAP] Starting Ollama service
  [BOOTSTRAP] Deploying Open WebUI container
  [BOOTSTRAP] Running validation checks
  [BOOTSTRAP] Enabling health monitoring timer
[RUNNER] Bootstrap complete - marking flag
[RUNNER] Rebooting if NVIDIA drivers were installed...
```

**Duration:** ~15-25 minutes depending on driver installation

**Monitor progress remotely:**

```bash
# From another machine
ssh daniel@192.168.128.5 "sudo journalctl -u local-llm-first-boot -f"

# Output will show:
# Sep 29 14:32:10 Skippy systemd[1]: Starting Local LLM First-Boot Initialization...
# Sep 29 14:32:15 Skippy local-llm-first-boot-runner[1234]: [2024-09-29] Waiting for NVIDIA...
# Sep 29 14:32:20 Skippy bootstrap-local-llm-host[5678]: Installing base packages...
# ... (progress updates)
# Sep 29 14:48:35 Skippy local-llm-first-boot-runner[1234]: SUCCESS: Bootstrap completed
```

### Phase 4: Verification (Manual)

**Objective:** Confirm that Skippy is fully operational

**SSH into host:**

```bash
ssh daniel@192.168.128.5
```

**Verify services:**

```bash
# Check all services are running
systemctl status ollama local-llm-open-webui.service -n 0

# Check GPU allocation
nvidia-smi
nvidia-smi -L

# View current configuration
cat /etc/default/local-llm

# Test inference
ollama run llama3.1:8b "Say ready"

# Check health
/usr/local/lib/local-llm-health-check.sh

# View health history
cat /var/lib/local-llm/.last-health-report
```

**Access Open WebUI:**

```
http://192.168.128.5:3000
```

## Monitoring & Health

### Automatic Health Checks

Health checks run automatically every 30 minutes (first check at 5 minutes after boot):

```bash
# View the timer
systemctl list-timers local-llm-health-check.timer

# Manually run a health check
sudo /usr/local/lib/local-llm-health-check.sh

# View health check logs
journalctl -u local-llm-health-check -n 50

# Check last health report
cat /var/lib/local-llm/.last-health-report
```

### Troubleshooting

**If first-boot doesn't run:**

```bash
# Check if the flag exists
ls -la /var/lib/local-llm/.bootstrap-complete

# View the bootstrap log
sudo journalctl -u local-llm-first-boot -a

# Check if service is enabled
systemctl is-enabled local-llm-first-boot.service

# Manually run bootstrap if needed
sudo /opt/local-llm-src/bootstrap-local-llm-host.sh
```

**If GPUs aren't detected:**

```bash
# Check NVIDIA driver
nvidia-smi -L

# Rerun GPU policy application
sudo /usr/local/bin/apply-ollama-gpu-policy.sh

# Restart Ollama with new policy
sudo systemctl restart ollama
systemctl show ollama --property=Environment
```

**If Open WebUI isn't responding:**

```bash
# Check service status
sudo systemctl status local-llm-open-webui.service

# View logs
sudo journalctl -u local-llm-open-webui.service -n 100

# Restart service
sudo systemctl restart local-llm-open-webui.service

# Verify port
sudo netstat -tlnp | grep 3000
```

## Rollback & Recovery

### If anything goes wrong:

1. **SSH in and check logs:**
   ```bash
   journalctl -b -1 -e  # Boot logs
   cat /var/log/local-llm-bootstrap.log
   ```

2. **Manual re-bootstrap:**
   ```bash
   sudo /opt/local-llm-src/bootstrap-local-llm-host.sh
   ```

3. **Reset and start over:**
   ```bash
   # Stop services
   sudo systemctl stop ollama local-llm-open-webui.service
   
   # Remove first-boot flag to trigger re-bootstrap on next reboot
   sudo rm /var/lib/local-llm/.bootstrap-complete
   
   # Reboot
   sudo reboot
   ```

4. **Full reinstall:**
   - Use prepared USB to boot and install again
   - Automation will run from scratch

## Advanced Configuration

### Custom Model on First Boot

Edit `/etc/default/local-llm` before first boot to set a first model:

```bash
LOCAL_LLM_FIRST_MODEL=mistral:7b
```

The bootstrap will automatically pull and validate this model.

### Custom Network Configuration

Edit the preseed parameters in `invoke-skippy-usb-automation.ps1` before USB prep:

```powershell
-StaticAddressCidr "192.168.128.5/24"
-Gateway "192.168.128.1"
-NameServers @("192.168.128.1", "1.1.1.1", "8.8.8.8")
```

Or use DHCP:

```powershell
-Dhcp
```

## Automation Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ Windows (Preparation Phase)                                     │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ 1. Generate Linux password hash                           │  │
│ │    new-linux-password-hash.ps1                           │  │
│ └────────────────────────────────────────────────────────────┘  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ 2. Prepare USB with full automation                        │  │
│ │    invoke-skippy-usb-automation.ps1                       │  │
│ │    → prepare-ubuntu-server-26.04-usb-autoinstall.ps1     │  │
│ │    → Copies all scripts + preseed.cfg                     │  │
│ └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Z8 G4 (Installation Phase - Unattended)                         │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ 3. Boot from USB + GRUB autoinstall parameter            │  │
│ │    Ubuntu Installer runs with preseed.cfg                │  │
│ │    - Partitioning                                         │  │
│ │    - User creation                                        │  │
│ │    - Package installation                                │  │
│ │    - Cloud-init late-commands                            │  │
│ │      → Copies artifacts to /opt/local-llm-src            │  │
│ │      → Installs first-boot service                       │  │
│ └────────────────────────────────────────────────────────────┘  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ 4. First Reboot - Cloud-init finalization                │  │
│ │    - Systemd enables local-llm-first-boot.service        │  │
│ └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Z8 G4 (First-Boot Automation Phase)                             │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ 5. local-llm-first-boot.service activates                │  │
│ │    local-llm-first-boot-runner.sh orchestrates:          │  │
│ │    - Wait for GPU detection                               │  │
│ │    - Execute bootstrap-local-llm-host.sh                 │  │
│ │      → Install Docker                                     │  │
│ │      → Install NVIDIA drivers (if needed)                │  │
│ │      → Install Ollama                                     │  │
│ │      → Copy Local_LLM configs                            │  │
│ │      → Apply GPU policy (0,1,2)                          │  │
│ │      → Start services                                     │  │
│ │      → Pull first model                                   │  │
│ │      → Run validation                                     │  │
│ │      → Enable health-check timer                          │  │
│ │    - Handle reboots if driver install needed             │  │
│ │    - Mark bootstrap complete                              │  │
│ │    - Enable periodic health monitoring                    │  │
│ └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Z8 G4 (Operational Phase)                                        │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ 6. Regular Operations                                     │  │
│ │    - Ollama running with all 3 GPUs                      │  │
│ │    - Open WebUI accessible at :3000                       │  │
│ │    - Health checks run every 30 minutes                  │  │
│ │    - Ready for LLM inference requests                     │  │
│ │                                                           │  │
│ │    ✓ Systemd timers keep services running                │  │
│ │    ✓ Auto-restart if service fails                       │  │
│ │    ✓ Logs available via journalctl                       │  │
│ └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Time Estimates

| Phase | Duration | Activity |
|-------|----------|----------|
| USB Prep | 2 minutes | PowerShell scripts |
| OS Install | 10-15 minutes | Ubuntu installer + cloud-init |
| First-Boot Bootstrap | 10-20 minutes | Docker, drivers, Ollama, validation |
| **Total** | **25-50 minutes** | Full deployment soup-to-nuts |

## Summary

This automation brings **hands-off deployment** to a complex Local_LLM stack. The only manual intervention needed is:

1. Generate password hash (PowerShell)
2. Boot from USB
3. Enter one GRUB parameter
4. SSH in after ~30 minutes to verify

Everything else—OS installation, Docker setup, NVIDIA drivers, Ollama, GPU allocation, and monitoring—happens automatically.
