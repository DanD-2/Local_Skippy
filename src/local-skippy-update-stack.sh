#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

env_file="$(load_env_file)"
image_name="${LOCAL_SKIPPY_WEBUI_IMAGE:-${LOCAL_LLM_WEBUI_IMAGE:-ghcr.io/open-webui/open-webui:main}}"
service_name="${LOCAL_SKIPPY_WEBUI_SERVICE_NAME:-local-llm-open-webui.service}"

if ! confirm_action "Proceed with app-stack update (Open WebUI image refresh and service restart)?"; then
    log_warn "update cancelled"
    exit 1
fi

if command -v docker >/dev/null 2>&1; then
    docker pull "$image_name"
else
    log_warn "docker not found; skipping image refresh"
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl restart ollama || log_warn "unable to restart ollama"
    systemctl restart "$service_name" || log_warn "unable to restart $service_name"
fi

log_info "update completed without touching GPU drivers"
log_info "env file: $env_file"
