# Operations

## Purpose

This document covers day-to-day operation of the Local Skippy AI appliance: starting and stopping services, updating models and software, backing up state, and recovering from failures.

## Service Overview

| Service | Manager | Status Check |
|---|---|---|
| Ollama | systemd | `systemctl status ollama` |
| Open WebUI | systemd (Docker-wrapped) | `systemctl status local-llm-open-webui.service` |
| Docker | systemd | `systemctl status docker` |

## Start and Stop

### Normal Start

All services are enabled at boot. After a clean reboot, no manual steps are needed.

```sh
# Verify all services are up after boot
systemctl status ollama --no-pager
systemctl status local-llm-open-webui.service --no-pager
sudo docker ps
```

### Manual Service Control

```sh
# Restart Ollama
sudo systemctl restart ollama

# Restart Open WebUI
sudo systemctl restart local-llm-open-webui.service

# Stop all AI services (maintenance)
sudo systemctl stop local-llm-open-webui.service
sudo systemctl stop ollama
```

### After Configuration Changes

After any change to `/etc/default/local-llm` or the GPU policy:

```sh
sudo apply-ollama-gpu-policy.sh
sudo systemctl daemon-reload
sudo systemctl restart ollama
sudo systemctl restart local-llm-open-webui.service
/usr/local/bin/validate-local-llm.sh
```

## Validation

Run the validation script after any service change:

```sh
/usr/local/bin/validate-local-llm.sh
```

This checks:

1. NVIDIA driver is loaded and GPU count is correct.
2. Ollama service is active.
3. Ollama API responds.
4. Open WebUI is reachable.
5. Docker container is running.

## Model Management

### Pull a New Model

```sh
ollama pull <model-name>
```

### List Loaded Models

```sh
ollama list
ollama ps
```

### Remove a Model

```sh
ollama rm <model-name>
```

### Check Model Disk Usage

```sh
du -sh /var/lib/ollama/models/
```

## Updates

### Ollama Update

```sh
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl restart ollama
/usr/local/bin/validate-local-llm.sh
```

### Open WebUI Update

```sh
sudo systemctl stop local-llm-open-webui.service
sudo docker pull ghcr.io/open-webui/open-webui:main
sudo systemctl start local-llm-open-webui.service
/usr/local/bin/validate-local-llm.sh
```

### System Updates

```sh
sudo apt update && sudo apt full-upgrade -y
sudo reboot
# After reboot:
/usr/local/bin/validate-local-llm.sh
```

After kernel or NVIDIA driver updates, always run `nvidia-smi` to confirm all three GPUs are still visible.

## Backup

### What to Back Up

| Item | Location | Priority |
|---|---|---|
| Open WebUI data | Docker volume `open-webui` | High — contains agent configs and conversations |
| Ollama models | `/var/lib/ollama/models/` | Medium — can be re-pulled but slow |
| Environment file | `/etc/default/local-llm` | High — contains runtime config |
| Systemd overrides | `/etc/systemd/system/ollama.service.d/` | High |
| Agent config files | `config/agents/*.yaml` in this repo | Maintained in git |

### Back Up Open WebUI Volume

```sh
sudo docker run --rm \
  -v open-webui:/data \
  -v /srv/backup:/backup \
  busybox tar czf /backup/open-webui-$(date +%Y%m%d).tar.gz /data
```

### Back Up Environment File

```sh
sudo cp /etc/default/local-llm /srv/backup/local-llm.env.$(date +%Y%m%d)
```

### Back Up Ollama Models (Optional)

Models can be re-pulled from Ollama. Only back them up if you have limited bandwidth or the model may be removed from the registry.

```sh
sudo rsync -av /var/lib/ollama/models/ /srv/backup/ollama-models/
```

## Recovery

### Service Fails to Start

1. Check `journalctl -u ollama -n 50` for Ollama errors.
2. Check `journalctl -u local-llm-open-webui.service -n 50` for WebUI errors.
3. Confirm Docker is running: `systemctl status docker`.
4. Confirm GPUs are visible: `nvidia-smi`.
5. Re-run `apply-ollama-gpu-policy.sh` and reload systemd if GPU settings changed.

### GPU Not Visible After Reboot

```sh
# Confirm driver is loaded
lsmod | grep nvidia

# Reinstall driver if missing
sudo ubuntu-drivers autoinstall
sudo reboot
```

### Open WebUI Container Missing

```sh
# Re-deploy the container
sudo systemctl restart local-llm-open-webui.service
# Or manually:
sudo /usr/local/bin/local-llm-run-open-webui.sh
```

### Full Host Recovery

1. Re-install Ubuntu Server 24.04 LTS from the install runbook.
2. Restore `/etc/default/local-llm` from backup.
3. Re-run the install runbook from Phase 3 (Docker and Ollama).
4. Restore the Open WebUI volume from backup.
5. Re-pull Ollama models.
6. Run validation.

## Monitoring

Useful ongoing monitoring commands:

```sh
# GPU utilization
nvidia-smi

# Loaded Ollama models and VRAM usage
ollama ps

# Disk usage
df -h

# Memory pressure
free -h

# Service health
systemctl status ollama local-llm-open-webui.service docker --no-pager
```

Consider setting up a simple cron-based health check that runs `validate-local-llm.sh` and alerts if it fails.
