#!/usr/bin/env sh
set -eu

LOCAL_SKIPPY_ENV_FILE_DEFAULT="/etc/local-skippy/local-skippy.env"
LOCAL_SKIPPY_LEGACY_ENV_FILE_DEFAULT="/etc/default/local-llm"

resolve_env_file() {
    if [ -n "${LOCAL_SKIPPY_ENV_FILE:-}" ]; then
        printf '%s\n' "$LOCAL_SKIPPY_ENV_FILE"
        return 0
    fi

    if [ -n "${LOCAL_LLM_ENV_FILE:-}" ]; then
        printf '%s\n' "$LOCAL_LLM_ENV_FILE"
        return 0
    fi

    if [ -f "$LOCAL_SKIPPY_ENV_FILE_DEFAULT" ]; then
        printf '%s\n' "$LOCAL_SKIPPY_ENV_FILE_DEFAULT"
        return 0
    fi

    printf '%s\n' "$LOCAL_SKIPPY_LEGACY_ENV_FILE_DEFAULT"
}

load_env_file() {
    env_file="$(resolve_env_file)"
    if [ -f "$env_file" ]; then
        # shellcheck disable=SC1090
        . "$env_file"
    fi
    printf '%s\n' "$env_file"
}

confirm_action() {
    prompt="$1"

    if [ "${LOCAL_SKIPPY_NONINTERACTIVE:-0}" = "1" ]; then
        return 0
    fi

    printf '%s [y/N]: ' "$prompt" >&2
    read -r answer || true

    case "$answer" in
        y|Y|yes|YES)
            return 0
            ;;
    esac

    return 1
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        printf 'this script must run as root\n' >&2
        exit 1
    fi
}

log_info() {
    printf '[local-skippy] %s\n' "$1"
}

log_warn() {
    printf '[local-skippy] warning: %s\n' "$1" >&2
}
