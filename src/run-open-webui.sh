#!/usr/bin/env sh
set -eu

environment_file="${LOCAL_LLM_ENV_FILE:-/etc/default/local-llm}"

if [ -f "$environment_file" ]; then
    # shellcheck disable=SC1090
    . "$environment_file"
fi

docker_bin="${LOCAL_LLM_DOCKER_BIN:-docker}"
container_name="${LOCAL_LLM_WEBUI_CONTAINER_NAME:-open-webui}"
image_name="${LOCAL_LLM_WEBUI_IMAGE:-ghcr.io/open-webui/open-webui:main}"
host_port="${LOCAL_LLM_WEBUI_PORT:-3000}"
container_port="${LOCAL_LLM_WEBUI_CONTAINER_PORT:-8080}"
data_volume="${LOCAL_LLM_WEBUI_VOLUME:-open-webui}"
ollama_base_url="${LOCAL_LLM_OLLAMA_BASE_URL:-http://host.docker.internal:11434}"

if ! command -v "$docker_bin" >/dev/null 2>&1; then
    printf 'docker command not found: %s\n' "$docker_bin" >&2
    exit 1
fi

if "$docker_bin" ps -a --format '{{.Names}}' | grep -qx "$container_name"; then
    "$docker_bin" rm -f "$container_name" >/dev/null
fi

exec "$docker_bin" run -d \
    --name "$container_name" \
    --restart unless-stopped \
    -p "$host_port:$container_port" \
    -e OLLAMA_BASE_URL="$ollama_base_url" \
    -v "$data_volume:/app/backend/data" \
    --add-host host.docker.internal:host-gateway \
    "$image_name"