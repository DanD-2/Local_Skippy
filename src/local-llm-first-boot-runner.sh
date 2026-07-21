#!/usr/bin/env bash
# First-boot automation runner for Local_LLM host
# Runs once on first boot after Ubuntu installation
# Coordinates with bootstrap-local-llm-host.sh

set -euo pipefail

BOOTSTRAP_LOG="/var/log/local-llm-bootstrap.log"
COMPLETE_FLAG="/var/lib/local-llm/.bootstrap-complete"
REBOOT_FLAG="/var/lib/local-llm/.reboot-required"
STATE_DIR="/var/lib/local-llm"
RETRY_COUNT=0
MAX_RETRIES=3

init_logging() {
    mkdir -p "$(dirname "$BOOTSTRAP_LOG")"
    mkdir -p "$STATE_DIR"
    exec 1> >(tee -a "$BOOTSTRAP_LOG")
    exec 2>&1
    echo "========================================" | tee -a "$BOOTSTRAP_LOG"
    echo "Local_LLM First-Boot Bootstrap" | tee -a "$BOOTSTRAP_LOG"
    echo "Started: $(date -u)" | tee -a "$BOOTSTRAP_LOG"
    echo "========================================" | tee -a "$BOOTSTRAP_LOG"
}

wait_for_nvidia() {
    echo "[$(date -u)] Waiting for NVIDIA GPU detection..."
    local max_wait=120
    local elapsed=0
    while [[ $elapsed -lt $max_wait ]]; do
        if command -v nvidia-smi >/dev/null 2>&1; then
            if nvidia-smi -L >/dev/null 2>&1; then
                echo "[$(date -u)] GPUs detected successfully"
                return 0
            fi
        fi
        sleep 5
        ((elapsed += 5))
    done
    echo "[$(date -u)] WARNING: GPU detection timed out after ${max_wait}s (driver may need manual installation)" >&2
    return 1
}

run_bootstrap() {
    echo "[$(date -u)] Running main bootstrap process..."
    if [[ -x /usr/local/lib/bootstrap-local-llm-host.sh ]]; then
        # Run bootstrap with environment variables from /etc/default/local-llm if it exists
        if [[ -f /etc/default/local-llm ]]; then
            set +u
            # shellcheck source=/dev/null
            source /etc/default/local-llm || true
            set -u
        fi
        
        /usr/local/lib/bootstrap-local-llm-host.sh || {
            local exit_code=$?
            echo "[$(date -u)] Bootstrap failed with exit code $exit_code" >&2
            return $exit_code
        }
    else
        echo "[$(date -u)] ERROR: bootstrap-local-llm-host.sh not found at /usr/local/lib/" >&2
        return 1
    fi
}

check_reboot_required() {
    if [[ -f "$REBOOT_FLAG" ]]; then
        echo "[$(date -u)] Reboot was required by bootstrap; rebooting in 30 seconds..."
        rm -f "$REBOOT_FLAG"
        sleep 30
        systemctl reboot || true
        sleep 60  # Give system time to reboot
        exit 0
    fi
}

validate_completion() {
    echo "[$(date -u)] Running post-bootstrap validation..."
    if command -v validate-local-llm >/dev/null 2>&1; then
        validate-local-llm || {
            echo "[$(date -u)] WARNING: Validation returned non-zero exit code" >&2
            return 1
        }
    else
        echo "[$(date -u)] WARNING: Validation script not found" >&2
        return 1
    fi
}

mark_complete() {
    touch "$COMPLETE_FLAG"
    echo "[$(date -u)] Bootstrap marked complete. Flag: $COMPLETE_FLAG"
}

main() {
    init_logging
    
    echo "[$(date -u)] Hostname: $(hostname)"
    echo "[$(date -u)] User: $(whoami)"
    echo "[$(date -u)] Kernel: $(uname -r)"
    
    wait_for_nvidia || true
    
    if ! run_bootstrap; then
        echo "[$(date -u)] ERROR: Bootstrap process failed" >&2
        echo "[$(date -u)] Completed: $(date -u)" | tee -a "$BOOTSTRAP_LOG"
        exit 1
    fi
    
    check_reboot_required
    
    if validate_completion; then
        mark_complete
        echo "[$(date -u)] SUCCESS: First-boot bootstrap completed successfully" | tee -a "$BOOTSTRAP_LOG"
        echo "[$(date -u)] Completed: $(date -u)" | tee -a "$BOOTSTRAP_LOG"
        echo "[$(date -u)] Local_LLM host is ready for operation" | tee -a "$BOOTSTRAP_LOG"
        exit 0
    else
        echo "[$(date -u)] WARNING: Validation had issues, but bootstrap completed" >&2
        mark_complete
        exit 0
    fi
}

main "$@"
