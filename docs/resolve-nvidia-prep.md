# DaVinci Resolve And NVIDIA Preparation

## Legacy Note

This document is legacy reference for the older mixed-workstation deployment path.

It is not part of the current primary Ubuntu Server 26.04 dedicated-host build.

## Purpose

Use this note before treating the HP Z8 G4 as both a Local_LLM host and a DaVinci Resolve workstation.

The goal is to keep the creative workstation stable while still allowing GPU-backed inference on the same machine.

## Core Rule

Resolve stability matters more than squeezing the largest possible LLM onto the workstation.

For this project:

1. Keep one RTX 4060 reserved for display and creative workloads.
2. Keep the driver path conservative.
3. Avoid unnecessary GPU-sharing experiments until Resolve is validated first.

## Recommended NVIDIA Posture

1. Use the Ubuntu-supported recommended NVIDIA driver path.
2. Avoid beta or unusually new drivers unless a specific Resolve issue forces a change.
3. Validate all GPUs with `nvidia-smi` before installing AI tooling.
4. Apply the Ollama GPU reservation policy before production LLM use.

## Recommended Validation Order

Validate in this order, not all at once:

1. Ubuntu Studio is installed and stable.
2. NVIDIA drivers are installed and all GPUs appear correctly.
3. Desktop session is stable after reboot.
4. DaVinci Resolve launches and basic editing works.
5. Only then add Ollama and Open WebUI.
6. Only after that begin longer Local_LLM sessions.

## Resolve-Specific Risk Areas On Linux

1. Codec handling can differ from Windows workflows.
2. Driver mismatches can show up as launch failures or unstable rendering.
3. Aggressive GPU contention can make the workstation feel unreliable even when services stay technically up.

## Practical Safeguards

1. Keep one GPU reserved for the desktop and Resolve.
2. Start Local_LLM with a smaller single-GPU-friendly model.
3. Avoid heavy inference while actively editing until the workstation proves stable.
4. Record the exact driver version once Resolve is behaving correctly.

## Recommended Host Checks

Run these on the workstation:

```sh
nvidia-smi
nvidia-smi -L
systemctl show ollama --property=Environment
cat /etc/systemd/system/ollama.service.d/override.conf
```

## Success Criteria

The mixed-workstation posture is acceptable when:

1. Resolve launches reliably.
2. Desktop responsiveness stays acceptable.
3. Ollama remains constrained to the intended GPUs.
4. Short Local_LLM sessions do not interfere with active editing work.