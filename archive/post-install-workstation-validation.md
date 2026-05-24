# Post-Install Workstation Validation

## Purpose

Use this checklist after the initial Ubuntu Studio and Local_LLM deployment on Skippy to prove that creative workloads and local inference can coexist acceptably.

This validation is specific to the current workstation posture:

1. Host: `Skippy.aybara.local`
2. IP: `192.168.128.5`
3. Admin user: `Daniel`
4. GPU policy: `2` GPUs for Local_LLM and `1` GPU reserved for desktop and creative applications

## Validation Goal

Confirm all of the following at the same time:

1. Ubuntu Studio is stable as a desktop.
2. Resolve launches and basic work is possible.
3. OBS Studio and browser workflows are usable.
4. The first CAD validation tool launches.
5. Local_LLM remains available without taking over the workstation.

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

## Step 2: Confirm GPU Reservation

Run:

```sh
cat /etc/default/local-llm
cat /etc/systemd/system/ollama.service.d/override.conf
systemctl show ollama --property=Environment
```

Expected result:

1. The LLM GPU list is constrained to the two inference GPUs.
2. One GPU remains outside the Ollama-visible set for desktop and creative workloads.

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

## Step 4: DaVinci Resolve Check

Validate:

1. Resolve launches successfully.
2. A simple project can be opened or created.
3. Basic playback and UI responsiveness remain acceptable.
4. The workstation does not become unstable while Ollama is idle in the background.

Use `docs/resolve-nvidia-prep.md` if any GPU or stability concerns appear.

## Step 5: OBS Studio Check

Validate:

1. OBS launches normally.
2. Basic scene setup works.
3. Preview remains responsive.
4. Running OBS does not obviously conflict with the current GPU reservation policy.

## Step 6: Browser And VS Code Check

Validate:

1. Chrome or the chosen browser launches cleanly.
2. Browser-based notes access works.
3. VS Code launches and can still use the LLM integration workflow you expect.

## Step 7: CAD Check

Validate one first-pass CAD path:

1. FreeCAD for 3D parametric evaluation.
2. Or LibreCAD if your first need is 2D drafting.

Expected result:

1. The application launches.
2. Basic interaction is responsive.
3. It does not obviously interfere with the LLM service while idle.

## Step 8: Mixed-Load Check

The most important validation is mixed use.

Run a short LLM request and then confirm the workstation is still usable for creative work.

Suggested sequence:

1. Keep Open WebUI running.
2. Open Resolve or the first CAD tool.
3. Run a short LLM prompt.
4. Confirm desktop responsiveness remains acceptable.

## Pass Criteria

Treat the workstation as acceptable for daily use only when:

1. Creative applications launch reliably.
2. The desktop stays responsive.
3. Local_LLM remains reachable.
4. GPU reservation is still intact after reboot and service restart.
5. None of the mixed-load checks reveal obvious instability.