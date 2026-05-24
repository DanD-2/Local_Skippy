#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

environment_file="$(resolve_env_file)"

if [ -f "$environment_file" ]; then
    # shellcheck disable=SC1090
    . "$environment_file"
fi

docker_bin="${LOCAL_LLM_DOCKER_BIN:-docker}"
container_name="${LOCAL_SKIPPY_WEBUI_CONTAINER_NAME:-${LOCAL_LLM_WEBUI_CONTAINER_NAME:-open-webui}}"
image_name="${LOCAL_SKIPPY_WEBUI_IMAGE:-${LOCAL_LLM_WEBUI_IMAGE:-ghcr.io/open-webui/open-webui:main}}"
host_port="${LOCAL_SKIPPY_WEBUI_PORT:-${LOCAL_LLM_WEBUI_PORT:-3000}}"
container_port="${LOCAL_SKIPPY_WEBUI_CONTAINER_PORT:-${LOCAL_LLM_WEBUI_CONTAINER_PORT:-8080}}"
data_volume="${LOCAL_SKIPPY_WEBUI_VOLUME:-${LOCAL_LLM_WEBUI_VOLUME:-open-webui}}"
ollama_base_url="${LOCAL_SKIPPY_OLLAMA_BASE_URL:-${LOCAL_LLM_OLLAMA_BASE_URL:-http://host.docker.internal:11434}}"
cloud_env_file="${LOCAL_SKIPPY_CLOUD_ENV_FILE:-/etc/local-skippy/cloud-provider.env}"
cpu_limit="${LOCAL_SKIPPY_WEBUI_CPU_LIMIT:-}"
memory_limit="${LOCAL_SKIPPY_WEBUI_MEMORY_LIMIT:-}"

if ! command -v "$docker_bin" >/dev/null 2>&1; then
    printf 'docker command not found: %s\n' "$docker_bin" >&2
    exit 1
fi

if "$docker_bin" ps -a --format '{{.Names}}' | grep -qx "$container_name"; then
    if ! confirm_action "Container $container_name already exists and will be replaced. Continue?"; then
        printf 'skipped replacing %s\n' "$container_name"
        exit 0
    fi
    "$docker_bin" rm -f "$container_name" >/dev/null
fi

set -- "$docker_bin" run -d \
    --name "$container_name" \
    --restart unless-stopped \
    -p "$host_port:$container_port" \
    -e OLLAMA_BASE_URL="$ollama_base_url" \
    -v "$data_volume:/app/backend/data" \
    --add-host host.docker.internal:host-gateway

if [ -n "$cpu_limit" ]; then
    set -- "$@" --cpus "$cpu_limit"
fi

if [ -n "$memory_limit" ]; then
    set -- "$@" --memory "$memory_limit"
fi

if [ -f "$cloud_env_file" ]; then
    set -- "$@" --env-file "$cloud_env_file"
fi

set -- "$@" "$image_name"
exec "$@"