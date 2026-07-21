#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${LOCAL_LLM_SOURCE_DIR:-/opt/local-llm-src}"
ENV_FILE="/etc/default/local-llm"
GPU_DEVICES="${LOCAL_LLM_GPU_DEVICES:-0,1,2}"
EXPECTED_GPUS="${LOCAL_LLM_EXPECTED_GPUS:-3}"
FIRST_MODEL="${LOCAL_LLM_FIRST_MODEL:-}"

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "This script must run as root." >&2
        exit 1
    fi
}

install_base_packages() {
    apt update
    apt full-upgrade -y
    apt install -y curl ca-certificates docker.io
    systemctl enable --now docker
}

install_nvidia_driver() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "nvidia-smi already available; skipping NVIDIA driver install"
        return
    fi

    if ubuntu-drivers devices >/dev/null 2>&1; then
        ubuntu-drivers autoinstall || true
    else
        echo "ubuntu-drivers did not return usable output; skipping NVIDIA auto-install" >&2
    fi
}

install_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    systemctl enable --now ollama
}

install_local_llm_assets() {
    install -m 644 "${SRC_DIR}/local-llm.env.example" "${ENV_FILE}"
    install -m 755 "${SRC_DIR}/apply-ollama-gpu-policy.sh" /usr/local/bin/apply-ollama-gpu-policy.sh
    install -m 755 "${SRC_DIR}/run-open-webui.sh" /usr/local/bin/local-llm-run-open-webui.sh
    install -m 755 "${SRC_DIR}/validate-local-llm.sh" /usr/local/bin/validate-local-llm.sh
    install -m 644 "${SRC_DIR}/local-llm-open-webui.service" /etc/systemd/system/local-llm-open-webui.service
    
    # Install automation infrastructure
    if [[ -f "${SRC_DIR}/local-llm-first-boot-runner.sh" ]]; then
        install -m 755 "${SRC_DIR}/local-llm-first-boot-runner.sh" /usr/local/lib/local-llm-first-boot-runner.sh
    fi
    
    if [[ -f "${SRC_DIR}/local-llm-health-check.sh" ]]; then
        install -m 755 "${SRC_DIR}/local-llm-health-check.sh" /usr/local/lib/local-llm-health-check.sh
    fi
    
    if [[ -f "${SRC_DIR}/local-llm-first-boot.service" ]]; then
        install -m 644 "${SRC_DIR}/local-llm-first-boot.service" /etc/systemd/system/local-llm-first-boot.service
    fi
    
    if [[ -f "${SRC_DIR}/local-llm-health-check.service" ]]; then
        install -m 644 "${SRC_DIR}/local-llm-health-check.service" /etc/systemd/system/local-llm-health-check.service
    fi
    
    if [[ -f "${SRC_DIR}/local-llm-health-check.timer" ]]; then
        install -m 644 "${SRC_DIR}/local-llm-health-check.timer" /etc/systemd/system/local-llm-health-check.timer
    fi
}

configure_env_file() {
    sed -i "s/^LOCAL_LLM_EXPECTED_GPUS=.*/LOCAL_LLM_EXPECTED_GPUS=${EXPECTED_GPUS}/" "${ENV_FILE}"
    sed -i "s/^LOCAL_LLM_GPU_DEVICES=.*/LOCAL_LLM_GPU_DEVICES=${GPU_DEVICES}/" "${ENV_FILE}"
}

start_services() {
    /usr/local/bin/apply-ollama-gpu-policy.sh
    systemctl daemon-reload
    systemctl restart ollama
    systemctl enable --now local-llm-open-webui.service
    
    # Enable health monitoring
    if systemctl list-unit-files | grep -q local-llm-health-check.timer; then
        systemctl enable --now local-llm-health-check.timer
    fi
}

pull_first_model_if_requested() {
    if [[ -n "${FIRST_MODEL}" ]]; then
        ollama pull "${FIRST_MODEL}"
    fi
}

run_validation() {
    /usr/local/bin/validate-local-llm.sh
}

main() {
    require_root

    if [[ ! -d "${SRC_DIR}" ]]; then
        echo "Missing source directory: ${SRC_DIR}" >&2
        exit 1
    fi

    install_base_packages
    install_nvidia_driver
    install_ollama
    install_local_llm_assets
    config"
    echo "=========================================="
    echo "Local_LLM bootstrap completed successfully"
    echo "=========================================="
    echo "Next steps:"
    echo "1. Verify services are running:"
    echo "   systemctl status ollama local-llm-open-webui"
    echo "2. Check health status:"
    echo "   /usr/local/lib/local-llm-health-check.sh"
    echo "3. Access Open WebUI at http://$(hostname -I | awk '{print $1}'):3000"
    echo ""
    echo "NVIDIA drivers are required. If this is the first install run,"
    echo "reboot the host and run this script again to finalize setup."
    echo "==========================================
    pull_first_model_if_requested
    run_validation

    echo "Local_LLM bootstrap completed successfully."
    echo "If NVIDIA drivers were newly installed, reboot and run this script again to finalize GPU validation."
}

main "$@"
