#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

printf '[local-skippy] running preflight...\n'
"$script_dir/local-skippy-preflight.sh"

printf '[local-skippy] initializing environment files...\n'
"$script_dir/local-skippy-init-env.sh"

printf '[local-skippy] generating agent scaffolding...\n'
"$script_dir/local-skippy-agent-scaffold.sh"

printf '[local-skippy] applying Ollama GPU + CPU policy...\n'
"$script_dir/apply-ollama-gpu-policy.sh"

printf '[local-skippy] deploying Open WebUI container...\n'
"$script_dir/run-open-webui.sh"

printf '[local-skippy] generating initial health report...\n'
"$script_dir/local-skippy-health-report.sh"

printf '[local-skippy] bootstrap finished\n'
