#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
. "$script_dir/local-skippy-common.sh"

require_root
env_file="$(load_env_file)"
agent_dir="/etc/local-skippy/agents"

mkdir -p "$agent_dir"
chmod 700 "$agent_dir"

cat > "$agent_dir/finance.md" <<'AGENT'
# Finance Agent
- Priority: highest
- Runtime posture: always-on
- Isolation posture: dedicated prompts, dedicated GPU priority order, restart-protected services
- Authority: reporting + pre-approved safe maintenance only
- Cloud posture: local-first, optional OpenAI-compatible fallback
AGENT

cat > "$agent_dir/infrastructure.md" <<'AGENT'
# Infrastructure Agent
- Priority: high
- Scope: read-only plus bounded Proxmox actions first
- Isolation posture: shared platform components with policy boundaries
- Authority: stop and ask before destructive operations
AGENT

cat > "$agent_dir/software-engineering.md" <<'AGENT'
# Software Engineering Agent
- Priority: medium
- Scope: repository automation and remote VS Code-friendly workflows
- Isolation posture: shared platform components
- Authority: stop and ask before risky actions
AGENT

cat > "$agent_dir/evaluator.md" <<'AGENT'
# Evaluator Agent
- Priority: medium
- Cadence: weekly reports
- Authority: report plus pre-approved safe maintenance only
- Safety: stop and ask on ambiguous or destructive operations
AGENT

chmod 600 "$agent_dir"/*.md
log_info "agent scaffolding generated in $agent_dir using $env_file"
