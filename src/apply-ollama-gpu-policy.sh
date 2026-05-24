#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

environment_file="$(resolve_env_file)"
override_dir="${LOCAL_LLM_OLLAMA_OVERRIDE_DIR:-/etc/systemd/system/ollama.service.d}"
override_file="$override_dir/override.conf"

if [ ! -f "$environment_file" ]; then
    printf 'missing environment file: %s\n' "$environment_file" >&2
    exit 1
fi

gpu_devices="${LOCAL_SKIPPY_GPU_PRIORITY_ORDER:-}"
finance_gpus=""
shared_gpus=""
cpu_quota=""

while IFS='=' read -r key value; do
    case "$key" in
        LOCAL_SKIPPY_GPU_PRIORITY_ORDER)
            gpu_devices="$value"
            ;;
        LOCAL_SKIPPY_FINANCE_GPU_DEVICES)
            finance_gpus="$value"
            ;;
        LOCAL_SKIPPY_SHARED_GPU_DEVICES)
            shared_gpus="$value"
            ;;
        LOCAL_SKIPPY_OLLAMA_CPU_QUOTA)
            cpu_quota="$value"
            ;;
        LOCAL_LLM_GPU_DEVICES)
            if [ -z "$gpu_devices" ]; then
                gpu_devices="$value"
            fi
            ;;
    esac
done < "$environment_file"

if [ -z "$gpu_devices" ] && [ -n "$finance_gpus" ] && [ -n "$shared_gpus" ]; then
    gpu_devices="$finance_gpus,$shared_gpus"
fi

if [ -z "$cpu_quota" ]; then
    cpu_quota="75%"
fi

if [ -z "$gpu_devices" ]; then
    printf 'LOCAL_SKIPPY_GPU_PRIORITY_ORDER or LOCAL_LLM_GPU_DEVICES is not set in %s\n' "$environment_file" >&2
    exit 1
fi

mkdir -p "$override_dir"

cat > "$override_file" <<EOF
[Service]
Environment=CUDA_VISIBLE_DEVICES=$gpu_devices
Environment=NVIDIA_VISIBLE_DEVICES=$gpu_devices
CPUQuota=$cpu_quota
EOF

printf 'wrote %s for GPUs %s\n' "$override_file" "$gpu_devices"
printf 'applied CPU quota %s for ollama.service\n' "$cpu_quota"
printf 'run: systemctl daemon-reload && systemctl restart ollama\n'