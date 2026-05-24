#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

env_file="$(load_env_file)"
backup_root="${LOCAL_SKIPPY_BACKUP_DIR:-/var/backups/local-skippy}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_file="$backup_root/local-skippy-$timestamp.tgz"

mkdir -p "$backup_root"

set --
for path in \
    /etc/local-skippy \
    /etc/systemd/system/ollama.service.d \
    /var/log/local-skippy \
    /var/lib/docker/volumes/open-webui/_data

do
    if [ -e "$path" ]; then
        set -- "$@" "$path"
    fi
done

if [ "$#" -eq 0 ]; then
    log_warn "nothing to back up"
    exit 1
fi

tar -czf "$backup_file" "$@"

log_info "backup created: $backup_file"
log_info "model blobs under /var/lib/ollama are intentionally excluded by default"
log_info "used environment file: $env_file"
