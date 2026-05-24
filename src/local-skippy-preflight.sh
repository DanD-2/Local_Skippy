#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

env_file="$(load_env_file)"

failures=0

check_command() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_warn "missing command: $cmd"
        failures=$((failures + 1))
    fi
}

check_command curl
check_command systemctl
check_command docker
check_command ollama

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [ "${ID:-}" != "ubuntu" ]; then
        log_warn "target OS is Ubuntu Server 26.04; detected ${ID:-unknown}"
        failures=$((failures + 1))
    fi

    case "${VERSION_ID:-}" in
        26.04|2[6-9].*|[3-9][0-9].*)
            ;;
        *)
            log_warn "target OS is Ubuntu Server 26.04 or newer; detected ${VERSION_ID:-unknown}"
            failures=$((failures + 1))
            ;;
    esac
else
    log_warn "cannot validate OS version because /etc/os-release is missing"
    failures=$((failures + 1))
fi

if ! systemctl is-enabled --quiet ollama 2>/dev/null; then
    log_warn "ollama service is not enabled"
fi

if ! systemctl is-active --quiet ollama 2>/dev/null; then
    log_warn "ollama service is not active"
fi

if [ ! -f "$env_file" ]; then
    log_warn "environment file not found: $env_file"
    failures=$((failures + 1))
fi

if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_count="$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l | tr -d ' ')"
    log_info "detected NVIDIA GPUs: $gpu_count"
else
    log_warn "nvidia-smi not found; GPU checks skipped"
fi

if [ "$failures" -gt 0 ]; then
    exit 1
fi

log_info "preflight checks passed"
