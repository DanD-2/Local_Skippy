#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

env_file="$(load_env_file)"
report_dir="${LOCAL_SKIPPY_REPORT_DIR:-/var/log/local-skippy/reports}"
mkdir -p "$report_dir"

report_file="$report_dir/health-$(date +%Y%m%d-%H%M%S).md"
ollama_host="${LOCAL_SKIPPY_OLLAMA_HOST:-${LOCAL_LLM_OLLAMA_HOST:-127.0.0.1:11434}}"
webui_url="${LOCAL_SKIPPY_WEBUI_URL:-${LOCAL_LLM_WEBUI_URL:-http://127.0.0.1:3000}}"

status_line() {
    label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf '%s\n' "- $label: OK"
    else
        printf '%s\n' "- $label: FAIL"
    fi
}

{
    printf '# Local Skippy Health Report\n\n'
    printf '%s\n' "- Generated: $(date -Iseconds)"
    printf '%s\n' "- Env file: $env_file"
    printf '%s\n\n' "- Load policy: ${LOCAL_SKIPPY_AI_LOAD_POLICY:-balanced}"

    printf '## Service Health\n'
    status_line 'ollama active' systemctl is-active --quiet ollama
    status_line 'docker active' systemctl is-active --quiet docker
    status_line 'open-webui container' sh -c "docker ps --format '{{.Names}}' | grep -qx '${LOCAL_SKIPPY_WEBUI_CONTAINER_NAME:-${LOCAL_LLM_WEBUI_CONTAINER_NAME:-open-webui}}'"

    printf '\n## Endpoint Checks\n'
    status_line "ollama API ($ollama_host)" curl --silent --show-error --fail --max-time 10 "http://$ollama_host/api/tags"
    status_line "open webui ($webui_url)" curl --silent --show-error --fail --max-time 10 "$webui_url"

    printf '\n## Resource Snapshot\n'
    printf '```\n'
    uptime || true
    printf '\n'
    free -h || true
    printf '\n'
    df -h / || true
    if command -v nvidia-smi >/dev/null 2>&1; then
        printf '\n'
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader || true
    fi
    printf '```\n\n'

    printf '## Safety Notes\n'
    printf '%s\n' '- Evaluator scope: report plus pre-approved safe maintenance only.'
    printf '%s\n' '- Risky or ambiguous operations should stop for human confirmation.'
} > "$report_file"

printf '%s\n' "$report_file"
