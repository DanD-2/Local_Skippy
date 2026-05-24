#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

environment_file="$(resolve_env_file)"
ollama_host="${LOCAL_SKIPPY_OLLAMA_HOST:-${LOCAL_LLM_OLLAMA_HOST:-127.0.0.1:11434}}"
webui_url="${LOCAL_SKIPPY_WEBUI_URL:-${LOCAL_LLM_WEBUI_URL:-http://127.0.0.1:3000}}"
expected_gpus="${LOCAL_SKIPPY_EXPECTED_GPUS:-${LOCAL_LLM_EXPECTED_GPUS:-}}"
webui_container_name="${LOCAL_SKIPPY_WEBUI_CONTAINER_NAME:-${LOCAL_LLM_WEBUI_CONTAINER_NAME:-open-webui}}"

if [ -f "$environment_file" ]; then
    # shellcheck disable=SC1090
    . "$environment_file"
fi

failures=0

check_command() {
    command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'missing command: %s\n' "$command_name" >&2
        failures=$((failures + 1))
    fi
}

check_http() {
    url="$1"
    if ! curl --silent --show-error --fail --max-time 10 "$url" >/dev/null 2>&1; then
        printf 'http check failed: %s\n' "$url" >&2
        failures=$((failures + 1))
    fi
}

check_command curl
check_command systemctl

if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_count="$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l | tr -d ' ')"
    if [ -n "$expected_gpus" ] && [ "$gpu_count" -lt "$expected_gpus" ]; then
        printf 'gpu count check failed: expected at least %s, found %s\n' "$expected_gpus" "$gpu_count" >&2
        failures=$((failures + 1))
    fi
else
    printf 'missing command: nvidia-smi\n' >&2
    failures=$((failures + 1))
fi

if ! systemctl is-active --quiet ollama; then
    printf 'service not active: ollama\n' >&2
    failures=$((failures + 1))
fi

check_http "http://$ollama_host/api/tags"
check_http "$webui_url"

if command -v docker >/dev/null 2>&1; then
    if ! docker ps --format '{{.Names}}' | grep -qx "$webui_container_name"; then
        printf 'container not running: %s\n' "$webui_container_name" >&2
        failures=$((failures + 1))
    fi
else
    printf 'missing command: docker\n' >&2
    failures=$((failures + 1))
fi

if [ "$failures" -gt 0 ]; then
    exit 1
fi

printf 'local-llm validation succeeded\n'
exit 0