#!/usr/bin/env sh
# weekly-review.sh — Evaluator agent weekly review and health check.
# Run automatically by the skippy-weekly-review.timer systemd timer,
# or manually with: sudo skippy-weekly-review.sh
set -eu

environment_file="${LOCAL_LLM_ENV_FILE:-/etc/default/skippy}"
log_dir="${SKIPPY_LOG_DIR:-/var/log/skippy}"

if [ -f "$environment_file" ]; then
    # shellcheck disable=SC1090
    . "$environment_file"
fi

report_date="$(date +%Y-%m-%d)"
report_file="${log_dir}/evaluation-${report_date}.md"
actions_log="${log_dir}/agent-actions.log"

mkdir -p "$log_dir"

log_action() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$actions_log"
}

# Helper: run a command and capture output safely
capture() {
    "$@" 2>&1 || printf '(command failed or unavailable)\n'
}

log_action "weekly-review.sh started"

# ── Collect data ───────────────────────────────────────────────────────────────

# Service status
ollama_status="$(systemctl is-active ollama 2>/dev/null || echo 'unknown')"
webui_status="$(systemctl is-active local-llm-open-webui 2>/dev/null || echo 'unknown')"

# GPU utilization
gpu_info="$(capture nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader)"

# RAM
ram_info="$(capture free -h)"

# CPU (from /proc/loadavg)
load_avg="$(cat /proc/loadavg 2>/dev/null || echo 'unavailable')"

# Disk usage
disk_root="$(df -h / 2>/dev/null | tail -1 || echo 'unavailable')"
disk_ollama="$(df -h /var/lib/ollama 2>/dev/null | tail -1 || echo 'unavailable')"
disk_docker="$(df -h /var/lib/docker 2>/dev/null | tail -1 || echo 'unavailable')"
disk_logs="$(df -h "$log_dir" 2>/dev/null | tail -1 || echo 'unavailable')"

# Ollama models
model_list="$(capture ollama list)"

# Docker containers
docker_list="$(capture docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}')"

# Recent Ollama journal errors (last 7 days)
ollama_errors="$(journalctl -u ollama --since '7 days ago' -p err -n 20 --no-pager 2>/dev/null || echo '(journalctl unavailable)')"

# Environment file permissions
env_perms="$(stat -c '%a %U:%G' "$environment_file" 2>/dev/null || echo 'unknown')"

# Firewall
ufw_status="$(ufw status 2>/dev/null || echo '(ufw unavailable)')"

# ── Auto-actions: Docker cleanup ──────────────────────────────────────────────
auto_actions=""

if command -v docker >/dev/null 2>&1; then
    pruned_containers="$(docker container prune -f 2>&1 || echo 'failed')"
    pruned_images="$(docker image prune -f 2>&1 || echo 'failed')"
    auto_actions="${auto_actions}
- docker container prune: ${pruned_containers}
- docker image prune: ${pruned_images}"
    log_action "auto-action: docker container and image prune"
fi

# ── Auto-actions: model currency check ────────────────────────────────────────
finance_model="${SKIPPY_FINANCE_MODEL:-nous-hermes2:34b-q4_K_M}"
infra_model="${SKIPPY_INFRA_MODEL:-nous-hermes2:13b-q4_K_M}"
softeng_model="${SKIPPY_SOFTENG_MODEL:-nous-hermes2-mixtral:8x7b-q4_K_M}"

model_update_notes=""
for model in "$finance_model" "$infra_model" "$softeng_model"; do
    if ollama list 2>/dev/null | grep -q "$(printf '%s' "$model" | cut -d: -f1)"; then
        # Pull the model — Ollama will skip if already current
        pull_result="$(ollama pull "$model" 2>&1 | tail -1 || echo 'pull failed')"
        model_update_notes="${model_update_notes}
- ${model}: ${pull_result}"
        log_action "auto-action: ollama pull ${model}: ${pull_result}"
    else
        model_update_notes="${model_update_notes}
- ${model}: NOT INSTALLED (run configure-agents.sh)"
    fi
done

# ── Write report ───────────────────────────────────────────────────────────────
cat > "$report_file" <<REPORT
# Skippy Weekly Evaluation — ${report_date}

## Summary

Weekly automated evaluation completed on ${report_date}.
Ollama: ${ollama_status}. Open WebUI: ${webui_status}.
Review the sections below for details and any proposed improvements.

## Service Health

- Ollama: ${ollama_status}
- Open WebUI: ${webui_status}
- Docker containers:

\`\`\`
${docker_list}
\`\`\`

### Recent Ollama Errors (last 7 days)

\`\`\`
${ollama_errors}
\`\`\`

## Resource Utilization

### GPU

\`\`\`
${gpu_info}
\`\`\`

### RAM

\`\`\`
${ram_info}
\`\`\`

### CPU Load Average

\`\`\`
${load_avg}
\`\`\`

## Disk Usage

| Mount             | Info                    |
|-------------------|-------------------------|
| /                 | ${disk_root}            |
| /var/lib/ollama   | ${disk_ollama}          |
| /var/lib/docker   | ${disk_docker}          |
| ${log_dir}        | ${disk_logs}            |

## Installed Models

\`\`\`
${model_list}
\`\`\`

## Model Update Results

${model_update_notes}

## Security Posture

- Environment file permissions: ${env_perms} (expected: 640 root:ollama)
- Firewall status:

\`\`\`
${ufw_status}
\`\`\`

## Actions Enacted Automatically

${auto_actions}

## Proposed Improvements

Review the sections above and add manual proposed improvements here.
The Evaluator agent can be prompted interactively in Open WebUI for deeper analysis.
All proposals requiring system or config changes require operator approval.

---

_Report generated by skippy-weekly-review.sh on ${report_date}_
REPORT

log_action "weekly report written: ${report_file}"

printf 'weekly evaluation complete: %s\n' "$report_file"
