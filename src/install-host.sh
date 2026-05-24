#!/usr/bin/env sh
# install-host.sh — Bootstrap Local Skippy on Ubuntu Server 24.04 LTS.
# Run as root or with sudo after the base Ubuntu Server install.
# This script is idempotent: safe to re-run.
set -eu

environment_file="${LOCAL_LLM_ENV_FILE:-/etc/default/skippy}"
log_dir="${SKIPPY_LOG_DIR:-/var/log/skippy}"

log() {
    printf '[install-host] %s\n' "$1"
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        printf 'This script must be run as root or with sudo.\n' >&2
        exit 1
    fi
}

require_root

# ── Docker CE ──────────────────────────────────────────────────────────────────
if ! command -v docker >/dev/null 2>&1; then
    log 'installing Docker CE...'
    apt-get update -qq
    apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    arch="$(dpkg --print-architecture)"
    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${codename} stable" \
        > /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
    log 'Docker CE installed.'
else
    log 'Docker CE already installed, skipping.'
fi

# ── NVIDIA Container Toolkit ───────────────────────────────────────────────────
if ! dpkg -l nvidia-container-toolkit >/dev/null 2>&1; then
    log 'installing NVIDIA Container Toolkit...'
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
        | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's|deb https://|deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://|g' \
        > /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt-get update -qq
    apt-get install -y nvidia-container-toolkit
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker
    log 'NVIDIA Container Toolkit installed.'
else
    log 'NVIDIA Container Toolkit already installed, skipping.'
fi

# ── Ollama ─────────────────────────────────────────────────────────────────────
if ! command -v ollama >/dev/null 2>&1; then
    log 'installing Ollama...'
    curl -fsSL https://ollama.com/install.sh | sh
    systemctl enable --now ollama
    log 'Ollama installed.'
else
    log 'Ollama already installed, running update...'
    curl -fsSL https://ollama.com/install.sh | sh
fi

# ── Add docker group membership for admin user ─────────────────────────────────
admin_user="${SUDO_USER:-daniel}"
if id "$admin_user" >/dev/null 2>&1; then
    if ! id -nG "$admin_user" | grep -qw docker; then
        usermod -aG docker "$admin_user"
        log "added ${admin_user} to docker group (log out and back in to take effect)"
    fi
fi

# ── Install helper scripts ─────────────────────────────────────────────────────
script_dir="$(cd "$(dirname "$0")" && pwd)"

install -m 755 "${script_dir}/apply-ollama-gpu-policy.sh"  /usr/local/bin/skippy-apply-gpu-policy.sh
install -m 755 "${script_dir}/run-open-webui.sh"            /usr/local/bin/local-llm-run-open-webui.sh
install -m 755 "${script_dir}/validate-local-llm.sh"        /usr/local/bin/skippy-validate.sh
install -m 755 "${script_dir}/weekly-review.sh"             /usr/local/bin/skippy-weekly-review.sh
install -m 755 "${script_dir}/configure-agents.sh"          /usr/local/bin/skippy-configure-agents.sh
log 'helper scripts installed to /usr/local/bin/'

# ── Install systemd service ────────────────────────────────────────────────────
install -m 644 "${script_dir}/local-llm-open-webui.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable local-llm-open-webui
log 'local-llm-open-webui systemd service installed and enabled.'

# ── Environment file ───────────────────────────────────────────────────────────
if [ ! -f "$environment_file" ]; then
    install -m 640 -o root -g ollama "${script_dir}/skippy.env.example" "$environment_file"
    log "environment file created at ${environment_file}"
    log "IMPORTANT: edit ${environment_file} and fill in all placeholder values."
else
    log "environment file already exists at ${environment_file}, not overwriting."
fi

# ── Log directory ──────────────────────────────────────────────────────────────
mkdir -p "$log_dir"
chmod 755 "$log_dir"
log "log directory ready: ${log_dir}"

# ── Apply GPU policy ───────────────────────────────────────────────────────────
if [ -f "$environment_file" ]; then
    LOCAL_LLM_ENV_FILE="$environment_file" /usr/local/bin/skippy-apply-gpu-policy.sh
    systemctl daemon-reload
    systemctl restart ollama
    log 'GPU policy applied and Ollama restarted.'
else
    log "WARNING: environment file missing — GPU policy not applied yet."
    log "Run: sudo skippy-apply-gpu-policy.sh  after editing ${environment_file}"
fi

log ''
log '── Install complete ──────────────────────────────────────────────────────'
log ''
log 'Next steps:'
log "  1. Edit ${environment_file} and fill in all placeholder values."
log "  2. Run: sudo skippy-configure-agents.sh"
log "  3. Run: sudo skippy-validate.sh"
log "  4. Open http://skippy.aybara.local:3000 in a browser."
