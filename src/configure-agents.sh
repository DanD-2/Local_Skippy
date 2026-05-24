#!/usr/bin/env sh
# configure-agents.sh — Pull all Hermes agent models and deploy Open WebUI.
# Run after install-host.sh and after /etc/default/skippy is configured.
# This script is idempotent: safe to re-run.
set -eu

environment_file="${LOCAL_LLM_ENV_FILE:-/etc/default/skippy}"

log() {
    printf '[configure-agents] %s\n' "$1"
}

if [ -f "$environment_file" ]; then
    # shellcheck disable=SC1090
    . "$environment_file"
fi

# ── Model configuration ────────────────────────────────────────────────────────
FINANCE_MODEL="${SKIPPY_FINANCE_MODEL:-nous-hermes2:34b-q4_K_M}"
INFRA_MODEL="${SKIPPY_INFRA_MODEL:-nous-hermes2:13b-q4_K_M}"
SOFTENG_MODEL="${SKIPPY_SOFTENG_MODEL:-nous-hermes2-mixtral:8x7b-q4_K_M}"
# Evaluator shares the infra model — no separate pull needed unless overridden.
EVALUATOR_MODEL="${SKIPPY_EVALUATOR_MODEL:-$INFRA_MODEL}"

# ── Verify Ollama is running ───────────────────────────────────────────────────
if ! command -v ollama >/dev/null 2>&1; then
    printf 'ollama command not found. Run src/install-host.sh first.\n' >&2
    exit 1
fi

if ! systemctl is-active --quiet ollama 2>/dev/null; then
    printf 'ollama service is not active. Start it with: systemctl start ollama\n' >&2
    exit 1
fi

# ── Pull agent models ──────────────────────────────────────────────────────────
log "pulling Finance agent model: ${FINANCE_MODEL}"
ollama pull "$FINANCE_MODEL"

log "pulling Infrastructure agent model: ${INFRA_MODEL}"
ollama pull "$INFRA_MODEL"

if [ "$SOFTENG_MODEL" != "$INFRA_MODEL" ] && [ "$SOFTENG_MODEL" != "$FINANCE_MODEL" ]; then
    log "pulling Software Engineering agent model: ${SOFTENG_MODEL}"
    ollama pull "$SOFTENG_MODEL"
fi

if [ "$EVALUATOR_MODEL" != "$INFRA_MODEL" ] && [ "$EVALUATOR_MODEL" != "$FINANCE_MODEL" ]; then
    log "pulling Evaluator agent model: ${EVALUATOR_MODEL}"
    ollama pull "$EVALUATOR_MODEL"
fi

log 'all agent models pulled.'

# ── Warm the Finance agent model (always-resident) ────────────────────────────
log "warming Finance agent model for always-resident operation..."
ollama run "$FINANCE_MODEL" "" 2>/dev/null || true
log "Finance agent model warmed."

# ── Deploy Open WebUI ──────────────────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
    log 'deploying Open WebUI container...'
    LOCAL_LLM_ENV_FILE="$environment_file" /usr/local/bin/local-llm-run-open-webui.sh
    log 'Open WebUI container deployed.'
else
    log 'WARNING: docker not found — Open WebUI container not deployed.'
fi

# ── Install weekly evaluation timer ───────────────────────────────────────────
log 'installing weekly evaluation systemd timer...'

cat > /tmp/skippy-weekly-review.service <<'EOF'
[Unit]
Description=Skippy Weekly Evaluation Review
After=ollama.service local-llm-open-webui.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/skippy-weekly-review.sh
EOF

cat > /tmp/skippy-weekly-review.timer <<'EOF'
[Unit]
Description=Skippy Weekly Evaluation Timer
Requires=skippy-weekly-review.service

[Timer]
OnCalendar=Sun *-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

install -m 644 /tmp/skippy-weekly-review.service /etc/systemd/system/
install -m 644 /tmp/skippy-weekly-review.timer    /etc/systemd/system/
rm -f /tmp/skippy-weekly-review.service /tmp/skippy-weekly-review.timer

systemctl daemon-reload
systemctl enable --now skippy-weekly-review.timer
log 'weekly evaluation timer installed and enabled.'

# ── List loaded models ─────────────────────────────────────────────────────────
log ''
log '── Agent configuration complete ──────────────────────────────────────────'
log ''
log 'Loaded models:'
ollama list
log ''
log 'Next steps:'
log '  1. Run: sudo skippy-validate.sh'
log '  2. Open http://skippy.aybara.local:3000 in a browser.'
log '  3. Create the Open WebUI admin account (first registration = admin).'
log '  4. Create individual user accounts.'
log '  5. Disable public registration in Open WebUI admin settings.'
