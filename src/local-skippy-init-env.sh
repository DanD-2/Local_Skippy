#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

require_root

config_dir="/etc/local-skippy"
main_env="$config_dir/local-skippy.env"
cloud_env="$config_dir/cloud-provider.env"

mkdir -p "$config_dir"
chmod 700 "$config_dir"

if [ ! -f "$main_env" ]; then
    install -m 600 "$script_dir/local-skippy.env.example" "$main_env"
    log_info "created $main_env"
else
    log_info "kept existing $main_env"
fi

if [ ! -f "$cloud_env" ]; then
    install -m 600 "$script_dir/cloud-provider.env.example" "$cloud_env"
    log_info "created $cloud_env"
else
    log_info "kept existing $cloud_env"
fi

mkdir -p /var/log/local-skippy/reports
chmod 750 /var/log/local-skippy /var/log/local-skippy/reports 2>/dev/null || true

log_info "environment initialization complete"
