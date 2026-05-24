# Operations — Start, Stop, Update, and Backup

## Service Overview

| Service                    | Managed by                        | Start on boot? |
|----------------------------|-----------------------------------|----------------|
| `ollama.service`           | systemd                           | Yes            |
| `local-llm-open-webui`     | systemd (wraps Docker)            | Yes            |
| Ollama model residency     | `/etc/default/skippy` env vars    | At first use   |
| Weekly evaluator           | `skippy-weekly-review.timer`      | Yes (scheduled)|

---

## Daily Operations

### Check service status

```bash
sudo systemctl status ollama local-llm-open-webui
sudo docker ps
sudo ollama ps
```

### Check GPU and resource utilization

```bash
nvidia-smi
free -h
top -bn1 | head -20
```

### Full stack validation

```bash
sudo /usr/local/bin/skippy-validate.sh
```

This is the canonical post-change check.  Run it after any service restart, model change, or
configuration update.

### View recent logs

```bash
# Ollama service log:
journalctl -u ollama -n 100 --no-pager

# Open WebUI container log:
journalctl -u local-llm-open-webui -n 100 --no-pager
docker logs open-webui --tail 50

# Weekly evaluation log:
ls /var/log/skippy/
```

---

## Restart Procedures

### Restart Open WebUI only

```bash
sudo systemctl restart local-llm-open-webui
sudo docker ps  # confirm container is running
```

### Restart Ollama only

```bash
sudo systemctl restart ollama
# Wait ~30 seconds for model reload if Finance agent model was resident:
ollama ps
```

### Restart the full stack

```bash
sudo systemctl restart ollama
sudo systemctl restart local-llm-open-webui
sudo /usr/local/bin/skippy-validate.sh
```

### Restart after host reboot

All services start automatically via systemd.  After a host reboot:

1. Wait 2–3 minutes for services to initialize.
2. Run `sudo /usr/local/bin/skippy-validate.sh` to confirm.
3. If the Finance agent model is not resident, warm it:
   ```bash
   ollama run nous-hermes2:34b-q4_K_M ""
   ```

---

## Model Management

### Pull a new model version

```bash
ollama pull nous-hermes2:34b-q4_K_M
```

### List loaded models

```bash
ollama ps
```

### List all downloaded models

```bash
ollama list
```

### Remove an unused model

```bash
ollama rm <model-name>
```

### Update all agent models to latest

The `src/weekly-review.sh` script handles this as part of the weekly evaluation cycle.  To
trigger manually:

```bash
sudo /usr/local/bin/skippy-weekly-review.sh --update-models-only
```

---

## Updating Open WebUI

```bash
# Pull the latest image:
docker pull ghcr.io/open-webui/open-webui:main

# Redeploy the container:
sudo /usr/local/bin/local-llm-run-open-webui.sh

# Confirm:
sudo systemctl status local-llm-open-webui
curl -sf http://127.0.0.1:3000 | head -5
```

---

## Updating Ollama

```bash
# Re-run the official installer (idempotent):
curl -fsSL https://ollama.com/install.sh | sh

# Restart and validate:
sudo systemctl restart ollama
sudo /usr/local/bin/skippy-validate.sh
```

---

## Updating the NVIDIA Driver

NVIDIA driver updates require a host reboot.  Plan for approximately 10 minutes of downtime.

```bash
# Check current driver version:
nvidia-smi | head -3

# Update via Ubuntu package:
sudo apt update && sudo apt upgrade -y nvidia-driver-550-server

# Reboot:
sudo reboot

# After reboot, validate:
nvidia-smi
sudo /usr/local/bin/skippy-validate.sh
```

---

## Backup

### What to back up

| Item                    | Path                              | Method           |
|-------------------------|-----------------------------------|------------------|
| Open WebUI data         | Docker volume `open-webui`        | docker export    |
| Environment config      | `/etc/default/skippy`             | Encrypted copy   |
| Agent config files      | `config/agents/`                  | Git              |
| Ollama models           | `/var/lib/ollama/models/`         | rsync (optional) |
| Weekly evaluation logs  | `/var/log/skippy/`                | rsync            |

### Backup Open WebUI volume

```bash
docker run --rm \
  -v open-webui:/data \
  -v /backup:/backup \
  alpine tar czf /backup/open-webui-$(date +%Y%m%d).tar.gz /data
```

### Backup environment config

```bash
# Use gpg encryption — never store plaintext credentials in backups accessible to others:
gpg --symmetric --cipher-algo AES256 /etc/default/skippy
# Move the resulting .gpg file to secure backup storage.
```

### Restore Open WebUI volume

```bash
docker run --rm \
  -v open-webui:/data \
  -v /backup:/backup \
  alpine tar xzf /backup/open-webui-YYYYMMDD.tar.gz -C /
sudo systemctl restart local-llm-open-webui
```

---

## Ollama Model Storage

Ollama models are large (4–35 GB each) and do not need to be in version-controlled backup.
Re-pulling models from the Ollama registry after a restore is the recommended approach.

Maintain a list of required models in `config/agents/*.yaml` so a restore procedure can pull
all required models in one pass via `src/configure-agents.sh`.

---

## Monitoring (Optional Phase 2)

For basic monitoring without a full observability stack, use:

```bash
# Cron-based disk usage alert:
echo "0 6 * * * root df -h | mail -s 'Skippy disk usage' daniel@yourdomain.local" \
  | sudo tee /etc/cron.d/skippy-disk-alert

# GPU temperature alert via nvidia-smi:
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader
```

For more complete monitoring, Grafana + Prometheus with `nvidia_gpu_exporter` and
`node_exporter` is the recommended stack, but it is outside the scope of this baseline.
