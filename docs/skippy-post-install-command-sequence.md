# Skippy Post-Install Command Sequence

## Purpose

Use this file after Ubuntu Server 26.04 is installed on Skippy and you can sign in as `daniel` over SSH.

This is the condensed command path tailored to the current target values.

## Assumptions

1. Hostname: `Skippy`
2. IP: `192.168.128.5`
3. Admin user: `daniel`
4. GPU posture: all `3` GPUs available to Local_LLM by default

## Step 1: Connect And Update

From PowerShell:

```powershell
ssh daniel@192.168.128.5
```

On the host:

```sh
hostnamectl
lsb_release -a
ip address
sudo apt update
sudo apt full-upgrade -y
sudo hostnamectl set-hostname Skippy
echo '192.168.128.5 Skippy.aybara.local Skippy' | sudo tee -a /etc/hosts
sudo reboot
```

Reconnect:

```powershell
ssh daniel@192.168.128.5
```

## Step 2: Install NVIDIA Driver

On the host:

```sh
lspci | grep -i nvidia
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot
```

Reconnect and validate:

```powershell
ssh daniel@192.168.128.5
```

```sh
nvidia-smi
nvidia-smi -L
```

## Step 3: Install Docker And Ollama

On the host:

```sh
sudo apt install -y docker.io
sudo systemctl enable --now docker
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable --now ollama
sudo systemctl status docker --no-pager
systemctl status ollama --no-pager
```

## Step 4: Copy Helper Artifacts

From PowerShell in the repo root:

```powershell
scp "src/local-llm.env.example" "src/apply-ollama-gpu-policy.sh" "src/run-open-webui.sh" "src/local-llm-open-webui.service" "src/validate-local-llm.sh" daniel@192.168.128.5:/tmp/
```

## Step 5: Install Helper Artifacts

On the host:

```sh
sudo install -m 644 /tmp/local-llm.env.example /etc/default/local-llm
sudo install -m 755 /tmp/apply-ollama-gpu-policy.sh /usr/local/bin/apply-ollama-gpu-policy.sh
sudo install -m 755 /tmp/run-open-webui.sh /usr/local/bin/local-llm-run-open-webui.sh
sudo install -m 755 /tmp/validate-local-llm.sh /usr/local/bin/validate-local-llm.sh
sudo install -m 644 /tmp/local-llm-open-webui.service /etc/systemd/system/local-llm-open-webui.service
```

## Step 6: Configure Local_LLM

On the host:

```sh
sudo tee /etc/default/local-llm >/dev/null <<'EOF'
LOCAL_LLM_EXPECTED_GPUS=3
LOCAL_LLM_GPU_DEVICES=0,1,2
LOCAL_LLM_OLLAMA_HOST=127.0.0.1:11434
LOCAL_LLM_OLLAMA_BASE_URL=http://host.docker.internal:11434
LOCAL_LLM_WEBUI_PORT=3000
LOCAL_LLM_WEBUI_CONTAINER_PORT=8080
LOCAL_LLM_WEBUI_CONTAINER_NAME=open-webui
LOCAL_LLM_WEBUI_VOLUME=open-webui
LOCAL_LLM_WEBUI_IMAGE=ghcr.io/open-webui/open-webui:main
LOCAL_LLM_WEBUI_URL=http://127.0.0.1:3000
EOF
```

## Step 7: Apply GPU Policy

On the host:

```sh
sudo /usr/local/bin/apply-ollama-gpu-policy.sh
sudo systemctl daemon-reload
sudo systemctl restart ollama
systemctl show ollama --property=Environment
cat /etc/systemd/system/ollama.service.d/override.conf
```

## Step 8: Pull A First Model

On the host:

```sh
ollama pull llama3.1:8b
ollama run llama3.1:8b "Respond with the word ready."
```

## Step 9: Enable Open WebUI

On the host:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now local-llm-open-webui.service
sudo systemctl status local-llm-open-webui.service --no-pager
sudo docker ps
curl -I http://127.0.0.1:3000
```

## Step 10: Validate

On the host:

```sh
sudo /usr/local/bin/validate-local-llm.sh
nvidia-smi
df -h
```

From another LAN machine:

```text
http://192.168.128.5:3000
```
