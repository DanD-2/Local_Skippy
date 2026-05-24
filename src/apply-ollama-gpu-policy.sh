#!/usr/bin/env sh
set -eu

environment_file="${LOCAL_LLM_ENV_FILE:-/etc/default/skippy}"
override_dir="${LOCAL_LLM_OLLAMA_OVERRIDE_DIR:-/etc/systemd/system/ollama.service.d}"
override_file="$override_dir/override.conf"

if [ ! -f "$environment_file" ]; then
    printf 'missing environment file: %s\n' "$environment_file" >&2
    exit 1
fi

gpu_devices=""
cpu_quota=""

while IFS='=' read -r key value; do
    case "$key" in
        LOCAL_LLM_GPU_DEVICES)
            gpu_devices="$value"
            ;;
        SKIPPY_OLLAMA_CPU_QUOTA)
            cpu_quota="$value"
            ;;
        OLLAMA_KEEP_ALIVE)
            keep_alive="$value"
            ;;
    esac
done < "$environment_file"

if [ -z "$gpu_devices" ]; then
    printf 'LOCAL_LLM_GPU_DEVICES is not set in %s\n' "$environment_file" >&2
    exit 1
fi

# Default CPU quota: 75% across 16 cores = 1200%
# Adjust SKIPPY_OLLAMA_CPU_QUOTA in the env file for your actual core count.
if [ -z "$cpu_quota" ]; then
    cpu_quota="1200%"
    printf 'SKIPPY_OLLAMA_CPU_QUOTA not set, using default: %s\n' "$cpu_quota"
fi

keep_alive="${keep_alive:--1}"

mkdir -p "$override_dir"

cat > "$override_file" <<EOF
[Service]
Environment=CUDA_VISIBLE_DEVICES=$gpu_devices
Environment=NVIDIA_VISIBLE_DEVICES=$gpu_devices
Environment=OLLAMA_KEEP_ALIVE=$keep_alive
CPUQuota=$cpu_quota
EOF

printf 'wrote %s\n' "$override_file"
printf '  GPUs:      %s\n' "$gpu_devices"
printf '  CPUQuota:  %s\n' "$cpu_quota"
printf '  KeepAlive: %s\n' "$keep_alive"
printf 'run: systemctl daemon-reload && systemctl restart ollama\n'