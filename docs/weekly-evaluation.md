# Weekly Evaluation — Evaluator Agent Schedule and Policy

## Purpose

The Evaluator agent runs a weekly review of the Skippy server and all four agents.  Its goal is
to identify improvement opportunities and, within defined safe limits, enact them.

---

## Schedule

| Event              | Default               | How to change                            |
|--------------------|-----------------------|------------------------------------------|
| Automatic run      | Sunday 02:00 UTC      | Edit `skippy-weekly-review.timer` unit   |
| Manual trigger     | `sudo skippy-weekly-review.sh` | Run at any time             |
| Report location    | `/var/log/skippy/`    | Configurable in `/etc/default/skippy`    |

---

## What the Evaluator Reviews

### 1. Service Health

- `systemctl status ollama` — any failed restarts or error messages.
- `systemctl status local-llm-open-webui` — container stability.
- `docker ps` — confirm Open WebUI container is running.

### 2. GPU, RAM, and CPU Utilization

- `nvidia-smi` — per-GPU temperature, utilization %, VRAM usage.
- `free -h` — RAM pressure.
- CPU utilization trends from journald.
- Assessment of whether the 75 % CPU policy target is being exceeded.

### 3. Disk Usage

- `/` (OS SSD) — flag if >80 % full.
- `/var/lib/ollama` — model storage growth.
- `/var/lib/docker` — Docker volume growth.
- `/var/log/skippy/` — log accumulation.

### 4. Agent Usage Summary

- Open WebUI conversation count per workspace (metadata only — not conversation content).
- Ollama model load events from journald.
- Any model load failures or timeout events.

### 5. Model Currency

- Compare installed model versions against the latest available from the Ollama registry.
- Flag models that have newer versions available.

### 6. Security Posture

- Check that `/etc/default/skippy` has correct permissions (`640`, `root:ollama`).
- Check SSH config for any unexpected changes.
- Check `ufw` firewall rules.

---

## Weekly Report Format

The report is saved as `/var/log/skippy/evaluation-YYYY-MM-DD.md`.

Required sections:

```markdown
# Skippy Weekly Evaluation — YYYY-MM-DD

## Summary
One-paragraph health summary.

## Service Health
- Ollama: [OK / WARN / FAIL] — details
- Open WebUI: [OK / WARN / FAIL] — details

## Resource Utilization
- GPU: average utilization, peak VRAM usage
- RAM: average free, peak usage
- CPU: average utilization, policy compliance

## Disk Usage
| Mount             | Used | Available | % Used | Status |
|-------------------|------|-----------|--------|--------|
| /                 | ...  | ...       | ...    | ...    |
| /var/lib/ollama   | ...  | ...       | ...    | ...    |

## Agent Usage
- Finance: N sessions this week
- Infrastructure: N sessions
- SoftwareEng: N sessions
- Evaluator: N sessions

## Model Currency
- nous-hermes2:34b-q4_K_M — current / update available: [version]
- nous-hermes2:13b-q4_K_M — current / update available: [version]
- nous-hermes2-mixtral:8x7b-q4_K_M — current / update available: [version]

## Security Posture
- skippy.env permissions: [OK / WARN]
- SSH config: [OK / WARN]
- Firewall: [OK / WARN]

## Actions Enacted Automatically
(list of any auto-actions taken this cycle, or "None")

## Proposed Improvements
1. [Description] — Approval required: [Yes/No]
2. ...
```

---

## Automation Boundaries

### Safe-to-enact automatically (no approval required)

The `weekly-review.sh` script may perform these actions without operator input:

1. `ollama pull <model>:<tag>` — update a model to a newer version within the same model family
   and quantization level.
2. Log rotation via `logrotate` for files under `/var/log/skippy/`.
3. Prune stopped Docker containers: `docker container prune -f`.
4. Remove dangling Docker images: `docker image prune -f`.

### Requires operator approval before enacting

The following improvements are written to the weekly report and flagged with
"**Approval required: Yes**".  The operator must review and approve them before action is taken:

1. Changing an agent's default model to a different model family.
2. Modifying systemd service configurations.
3. Adding new external AI provider connections.
4. Any change to network/firewall rules.
5. Any Proxmox actions.
6. Upgrading Ollama or the NVIDIA driver.
7. Any change that could affect the Finance agent's uptime or model residency.

---

## systemd Timer Setup

The weekly evaluation runs as a systemd timer.  Install it as part of `src/configure-agents.sh`
or manually:

```bash
# Copy the timer and service units:
sudo tee /etc/systemd/system/skippy-weekly-review.service > /dev/null <<'EOF'
[Unit]
Description=Skippy Weekly Evaluation Review
After=ollama.service local-llm-open-webui.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/skippy-weekly-review.sh
EOF

sudo tee /etc/systemd/system/skippy-weekly-review.timer > /dev/null <<'EOF'
[Unit]
Description=Skippy Weekly Evaluation Timer
Requires=skippy-weekly-review.service

[Timer]
OnCalendar=Sun *-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now skippy-weekly-review.timer
systemctl list-timers skippy-weekly-review.timer
```

---

## Manual Evaluation Trigger

```bash
sudo /usr/local/bin/skippy-weekly-review.sh
cat /var/log/skippy/evaluation-$(date +%Y-%m-%d).md
```

---

## Reviewing Past Reports

```bash
ls -lh /var/log/skippy/evaluation-*.md
cat /var/log/skippy/evaluation-YYYY-MM-DD.md
```

---

## Responding to Proposed Improvements

After reading the weekly report:

1. For "Approval required: No" items — they were already enacted.  Review the **Actions Enacted
   Automatically** section to confirm they are acceptable.
2. For "Approval required: Yes" items — decide for each:
   - Accept: implement the proposed change manually (or ask the relevant agent to help).
   - Defer: add a note in the next week's report context.
   - Reject: document the reason in `/var/log/skippy/agent-actions.log`.
