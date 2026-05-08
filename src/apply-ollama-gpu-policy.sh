#!/usr/bin/env sh
set -eu

environment_file="${LOCAL_LLM_ENV_FILE:-/etc/default/local-llm}"
override_dir="${LOCAL_LLM_OLLAMA_OVERRIDE_DIR:-/etc/systemd/system/ollama.service.d}"
override_file="$override_dir/override.conf"

if [ ! -f "$environment_file" ]; then
    printf 'missing environment file: %s\n' "$environment_file" >&2
    exit 1
fi

gpu_devices=""

while IFS='=' read -r key value; do
    case "$key" in
        LOCAL_LLM_GPU_DEVICES)
            gpu_devices="$value"
            ;;
    esac
done < "$environment_file"

if [ -z "$gpu_devices" ]; then
    printf 'LOCAL_LLM_GPU_DEVICES is not set in %s\n' "$environment_file" >&2
    exit 1
fi

mkdir -p "$override_dir"

cat > "$override_file" <<EOF
[Service]
Environment=CUDA_VISIBLE_DEVICES=$gpu_devices
Environment=NVIDIA_VISIBLE_DEVICES=$gpu_devices
EOF

printf 'wrote %s for GPUs %s\n' "$override_file" "$gpu_devices"
printf 'run: systemctl daemon-reload && systemctl restart ollama\n'