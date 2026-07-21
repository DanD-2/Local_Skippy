#!/usr/bin/env bash
# Local_LLM Health Check - Runs periodically via systemd timer
# Validates that all services are operational

set -euo pipefail

HEALTH_LOG="/var/log/local-llm-health.log"
STATE_DIR="/var/lib/local-llm"
REPORT_FILE="$STATE_DIR/.last-health-report"

init_logging() {
    mkdir -p "$(dirname "$HEALTH_LOG")"
    mkdir -p "$STATE_DIR"
}

log_check() {
    echo "[$(date -u)] $1" | tee -a "$HEALTH_LOG"
}

check_ollama_service() {
    log_check "Checking Ollama service..."
    if systemctl is-active --quiet ollama; then
        log_check "✓ Ollama service is active"
        return 0
    else
        log_check "✗ Ollama service is INACTIVE"
        return 1
    fi
}

check_ollama_endpoint() {
    log_check "Checking Ollama endpoint..."
    if timeout 5 curl -s http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
        log_check "✓ Ollama endpoint responding"
        return 0
    else
        log_check "✗ Ollama endpoint NOT responding"
        return 1
    fi
}

check_webui_service() {
    log_check "Checking Open WebUI service..."
    if systemctl is-active --quiet local-llm-open-webui.service; then
        log_check "✓ Open WebUI service is active"
        return 0
    else
        log_check "✗ Open WebUI service is INACTIVE"
        return 1
    fi
}

check_webui_endpoint() {
    log_check "Checking Open WebUI endpoint..."
    if timeout 5 curl -s http://127.0.0.1:3000 >/dev/null 2>&1; then
        log_check "✓ Open WebUI endpoint responding"
        return 0
    else
        log_check "✗ Open WebUI endpoint NOT responding"
        return 1
    fi
}

check_gpus() {
    log_check "Checking GPU status..."
    if command -v nvidia-smi >/dev/null 2>&1; then
        local gpu_count
        gpu_count=$(nvidia-smi -L 2>/dev/null | wc -l || echo "0")
        log_check "✓ GPUs detected: $gpu_count"
        return 0
    else
        log_check "✗ nvidia-smi not available"
        return 1
    fi
}

check_disk_space() {
    log_check "Checking disk space..."
    local llm_disk
    llm_disk=$(df /var/lib/ollama 2>/dev/null | awk 'NR==2 {print int($4 / 1024)} END {if (NR < 2) print "UNKNOWN"}')
    if [[ "$llm_disk" == "UNKNOWN" ]]; then
        log_check "⚠ Could not determine LLM disk free space"
        return 1
    elif [[ $llm_disk -gt 1024 ]]; then
        log_check "✓ LLM disk free: ${llm_disk} MB"
        return 0
    else
        log_check "✗ LLM disk LOW: only ${llm_disk} MB free"
        return 1
    fi
}

generate_report() {
    local check_count=$1
    local pass_count=$2
    
    cat > "$REPORT_FILE" <<EOF
Health Check Report
Generated: $(date -u)
Hostname: $(hostname)
Uptime: $(uptime -p)

Status Summary:
- Total Checks: $check_count
- Passed: $pass_count
- Failed: $((check_count - pass_count))

Last Full Log: $HEALTH_LOG
EOF
    
    log_check "Health report written to $REPORT_FILE"
}

main() {
    init_logging
    
    log_check "========================================="
    log_check "Local_LLM Health Check"
    log_check "Started: $(date -u)"
    log_check "========================================="
    
    local check_count=0
    local pass_count=0
    
    # Run all checks
    for check_func in check_ollama_service check_ollama_endpoint check_webui_service check_webui_endpoint check_gpus check_disk_space; do
        ((check_count++))
        if $check_func; then
            ((pass_count++))
        fi
    done
    
    generate_report "$check_count" "$pass_count"
    
    log_check "========================================="
    if [[ $pass_count -eq $check_count ]]; then
        log_check "Health Status: HEALTHY"
        log_check "========================================="
        exit 0
    else
        log_check "Health Status: DEGRADED ($pass_count/$check_count checks passed)"
        log_check "========================================="
        exit 1
    fi
}

main "$@"
