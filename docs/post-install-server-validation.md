# Post-Install Server Validation

## Purpose

Use this checklist after the initial Ubuntu Server 26.04 and Local_LLM deployment on Skippy to prove that the headless server posture is operational.

This validation is specific to the current server posture:

1. Host: `Skippy.aybara.local`
2. IP: `192.168.128.5`
3. Admin user: `daniel`
4. GPU policy: all `3` GPUs available to Local_LLM by default

## Validation Goal

Confirm all of the following:

1. SSH administration works.
2. Ollama is healthy.
3. Open WebUI is healthy.
4. The configured GPU list matches the intended server posture.
5. The host survives reboot without manual recovery.

## Step 1: Baseline Host Checks

Run:

```sh
hostnamectl
ip address
nvidia-smi
nvidia-smi -L
df -h
systemctl status ollama --no-pager
systemctl status local-llm-open-webui.service --no-pager
```

Expected result:

1. Hostname is correct.
2. All three GPUs are visible.
3. Ollama and Open WebUI are active.
4. Disk usage is reasonable on both SSDs.

## Step 2: Confirm GPU Exposure

Run:

```sh
cat /etc/default/local-llm
cat /etc/systemd/system/ollama.service.d/override.conf
systemctl show ollama --property=Environment
```

Expected result:

1. The LLM GPU list matches the intended inference device set.
2. The service environment matches the environment file.
3. If all GPUs are intended for inference, no accidental restriction is present.

## Step 3: Local_LLM Functional Check

Run:

```sh
ollama run llama3.1:8b "Reply with the word online."
curl -I http://127.0.0.1:3000
sudo /usr/local/bin/validate-local-llm.sh
```

Expected result:

1. Local inference succeeds.
2. Open WebUI answers locally.
3. The helper validation script passes.

## Step 4: LAN Reachability Check

From another LAN machine, open:

```text
http://192.168.128.5:3000
```

Expected result:

1. The login or setup page loads.
2. The UI can reach the local Ollama backend.

## Step 5: Reboot Check

Run:

```sh
sudo reboot
```

After reconnecting, run:

```sh
systemctl status ollama --no-pager
systemctl status local-llm-open-webui.service --no-pager
sudo docker ps
sudo /usr/local/bin/validate-local-llm.sh
```

Expected result:

1. Ollama restarts automatically.
2. Open WebUI restarts automatically.
3. The validation helper still passes.

## Pass Criteria

Treat the host as acceptable for daily use only when:

1. SSH administration is stable.
2. Ollama launches reliably.
3. Open WebUI remains reachable locally and from the LAN.
4. GPU exposure matches the intended server posture after reboot and service restart.
5. None of the checks reveal manual recovery steps or obvious instability.
