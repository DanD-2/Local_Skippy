#!/usr/bin/env sh
set -eu

environment_file="${LOCAL_LLM_ENV_FILE:-/etc/default/skippy}"
ollama_host="${LOCAL_LLM_OLLAMA_HOST:-127.0.0.1:11434}"
webui_url="${LOCAL_LLM_WEBUI_URL:-http://127.0.0.1:3000}"
expected_gpus="${LOCAL_LLM_EXPECTED_GPUS:-}"

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

# ── GPU validation ─────────────────────────────────────────────────────────────
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_count="$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l | tr -d ' ')"
    if [ -n "$expected_gpus" ] && [ "$gpu_count" -lt "$expected_gpus" ]; then
        printf 'gpu count check failed: expected at least %s, found %s\n' "$expected_gpus" "$gpu_count" >&2
        failures=$((failures + 1))
    else
        printf 'gpus found: %s\n' "$gpu_count"
    fi
else
    printf 'missing command: nvidia-smi\n' >&2
    failures=$((failures + 1))
fi

# ── Service validation ─────────────────────────────────────────────────────────
if ! systemctl is-active --quiet ollama; then
    printf 'service not active: ollama\n' >&2
    failures=$((failures + 1))
else
    printf 'service active: ollama\n'
fi

if ! systemctl is-active --quiet local-llm-open-webui; then
    printf 'service not active: local-llm-open-webui\n' >&2
    failures=$((failures + 1))
else
    printf 'service active: local-llm-open-webui\n'
fi

# ── Endpoint validation ────────────────────────────────────────────────────────
check_http "http://$ollama_host/api/tags"
printf 'endpoint reachable: http://%s/api/tags\n' "$ollama_host"

check_http "$webui_url"
printf 'endpoint reachable: %s\n' "$webui_url"

# ── Docker container validation ────────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
    container_name="${LOCAL_LLM_WEBUI_CONTAINER_NAME:-open-webui}"
    if ! docker ps --format '{{.Names}}' | grep -qx "$container_name"; then
        printf 'container not running: %s\n' "$container_name" >&2
        failures=$((failures + 1))
    else
        printf 'container running: %s\n' "$container_name"
    fi
else
    printf 'missing command: docker\n' >&2
    failures=$((failures + 1))
fi

# ── Agent model validation ─────────────────────────────────────────────────────
# Check that the Finance agent model (always-resident) is loaded.
finance_model="${SKIPPY_FINANCE_MODEL:-nous-hermes2:34b-q4_K_M}"
if command -v ollama >/dev/null 2>&1; then
    if ollama list 2>/dev/null | grep -q "$(printf '%s' "$finance_model" | cut -d: -f1)"; then
        printf 'finance agent model present: %s\n' "$finance_model"
    else
        printf 'finance agent model not found: %s (run: ollama pull %s)\n' \
            "$finance_model" "$finance_model" >&2
        failures=$((failures + 1))
    fi
fi

# ── Environment file permissions ──────────────────────────────────────────────
if [ -f "$environment_file" ]; then
    perms="$(stat -c '%a' "$environment_file" 2>/dev/null || stat -f '%Lp' "$environment_file" 2>/dev/null || echo 'unknown')"
    if [ "$perms" = "640" ] || [ "$perms" = "600" ]; then
        printf 'env file permissions ok: %s (%s)\n' "$environment_file" "$perms"
    else
        printf 'env file permissions warning: %s has %s (expected 640)\n' \
            "$environment_file" "$perms" >&2
        failures=$((failures + 1))
    fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────
if [ "$failures" -gt 0 ]; then
    printf '\nvalidation failed: %d check(s) failed\n' "$failures" >&2
    exit 1
fi

printf '\nskippy validation succeeded\n'
exit 0