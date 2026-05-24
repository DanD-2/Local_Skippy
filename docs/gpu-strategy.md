# GPU Strategy — Full GPU Inference with RAM and CPU Overflow

## Principle

All three NVIDIA GeForce RTX 4060 GPUs on Skippy are dedicated to AI inference.  No GPU is
reserved for a desktop display or workstation use — the system is headless.

Inference uses compute resources in this priority order:

1. **GPU VRAM** — primary, fastest tier.
2. **System RAM** — secondary overflow tier.
3. **CPU** — tertiary overflow, capped at 75 % sustained utilization.

---

## GPU Configuration

### Hardware

| Device | GPU                          | VRAM   |
|--------|------------------------------|--------|
| GPU 0  | NVIDIA GeForce RTX 4060      | 8 GB   |
| GPU 1  | NVIDIA GeForce RTX 4060      | 8 GB   |
| GPU 2  | NVIDIA GeForce RTX 4060      | 8 GB   |
| Total  |                              | 24 GB  |

All three GPUs are exposed to Ollama via `CUDA_VISIBLE_DEVICES=0,1,2`.

### Ollama GPU Exposure

Ollama uses all available NVIDIA GPUs automatically when the CUDA environment is correct.
The `src/apply-ollama-gpu-policy.sh` script writes the systemd override that sets
`CUDA_VISIBLE_DEVICES` and `NVIDIA_VISIBLE_DEVICES` to expose all three GPUs.

Verify GPU allocation after deployment:

```bash
nvidia-smi
ollama ps
```

`ollama ps` shows which GPUs each loaded model is using and how much VRAM is consumed.

---

## RAM Overflow

When a model's total size exceeds available VRAM, Ollama automatically offloads layers to system
RAM.  The 128 GB of system RAM provides a very large overflow pool.

Example hybrid allocation for a 34B Q4_K_M model (~20 GB):

- All 24 GB VRAM used across three GPUs.
- Remaining layers loaded into system RAM.
- Inference latency increases compared to full VRAM fit, but the model remains fully functional.

To monitor RAM pressure:

```bash
free -h
watch -n 5 free -h
```

---

## CPU Overflow Policy

CPU inference is the slowest tier and should be avoided for interactive workloads where possible.
However, it provides a fallback when GPU and RAM capacity are exhausted.

### Target Policy: ≤ 75 % Sustained CPU Utilization

The `ollama.service` systemd unit includes a CPU quota to enforce this policy:

```ini
[Service]
CPUQuota=300%
```

`CPUQuota=300%` on a multi-core system limits Ollama to at most 3 CPU cores worth of sustained
load (300 % = 3 × 100 %).  For a typical server CPU with 8+ cores, this provides meaningful AI
overflow capacity while preserving host stability for SSH, Docker, and other services.

Adjust `CPUQuota` based on the actual CPU core count of the Z8 G4:

| CPU cores available | Recommended CPUQuota for 75 % target |
|---------------------|--------------------------------------|
| 8 cores             | 600%                                 |
| 16 cores            | 1200%                                |
| 24 cores            | 1800%                                |
| 32 cores            | 2400%                                |

Check core count:

```bash
nproc --all
```

Set the quota in the Ollama systemd override (managed by `src/apply-ollama-gpu-policy.sh`):

```bash
sudo src/apply-ollama-gpu-policy.sh
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### Monitoring CPU Utilization

```bash
# Live system-wide CPU:
top -d 2

# Ollama process only:
pidstat -u -p $(pgrep ollama) 5

# Systemd cgroup accounting:
systemctl status ollama
```

---

## Model Loading Strategy

Ollama loads models into the fastest available tier automatically.

### Finance Agent — Always Resident

The Finance agent model is kept resident at all times using the Ollama keep-alive option.
This avoids cold-load latency for the highest-priority agent:

```bash
# Pull and warm the Finance agent model:
ollama run nous-hermes2:34b-q4_K_M ""
# Set keep-alive to -1 (never unload) via OLLAMA_KEEP_ALIVE env:
```

In `/etc/default/skippy`:

```
OLLAMA_KEEP_ALIVE=-1
```

This keeps any model loaded indefinitely once first used.  For the Finance agent, trigger an
initial load at boot time via `src/configure-agents.sh`.

### Other Agents — On-Demand

Infrastructure, Software Engineering, and Evaluator agent models load when first requested and
are unloaded after the default idle timeout (5 minutes).  Adjust `OLLAMA_KEEP_ALIVE` in the env
file if longer residency is preferred for frequently used agents.

---

## Choosing Model Sizes for the Available VRAM Budget

| Quantization   | ~VRAM for 7B | ~VRAM for 13B | ~VRAM for 34B |
|----------------|--------------|---------------|---------------|
| Q4_K_M         | ~4.5 GB      | ~8 GB         | ~20 GB        |
| Q5_K_M         | ~5 GB        | ~9 GB         | ~23 GB        |
| Q8_0           | ~7 GB        | ~14 GB        | ~35 GB        |

With 24 GB total VRAM:

- A single 34B Q4_K_M model uses ~20 GB — fits with room for system overhead.
- Two simultaneous 13B Q4_K_M models (~8 GB each) use 16 GB — fits entirely in VRAM.
- The Finance 34B model plus one 13B agent model simultaneously = ~28 GB — overflows ~4 GB to RAM.

Use Q4_K_M quantization as the default balance of quality and VRAM efficiency.
Use Q5_K_M for the Finance agent if response quality improvement justifies the extra VRAM.

See `docs/model-recommendations.md` for specific model pull commands per agent.
