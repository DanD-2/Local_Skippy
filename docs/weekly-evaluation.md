# Weekly Evaluation

## Purpose

This document defines the workflow for the Evaluator agent's weekly review of the Local Skippy appliance.

The Evaluator **proposes** improvements. It does **not** enact them automatically.

## Evaluation Scope

Each weekly evaluation covers:

1. GPU and resource utilization trends.
2. Ollama service reliability and error history.
3. Open WebUI usage and agent response quality.
4. Disk space consumption and growth trends.
5. Model performance and sizing observations.
6. Proposed improvements to agent configurations or resource policies.

## Operator Steps

Before running the weekly evaluation:

1. Collect the relevant logs and metrics.
2. Open the Evaluator agent in Open WebUI.
3. Provide the collected data as input.
4. Request a structured report.
5. Review the report and decide which proposals (if any) to implement.

## Collecting Input Data

Run these commands on the Skippy host and copy the output:

```sh
# GPU utilization snapshot
nvidia-smi

# Loaded models and VRAM usage
ollama ps

# Disk usage
df -h

# Memory
free -h

# Service status
systemctl status ollama local-llm-open-webui.service --no-pager

# Recent Ollama errors (last 7 days)
journalctl -u ollama --since "7 days ago" --no-pager | grep -i error | tail -50

# Recent WebUI errors
journalctl -u local-llm-open-webui.service --since "7 days ago" --no-pager | grep -i error | tail -50

# Validation result
/usr/local/bin/validate-local-llm.sh
```

## Evaluator Prompt Template

Provide this structure to the Evaluator agent:

```
Weekly evaluation input for Local Skippy — [DATE]

## GPU Status
[paste nvidia-smi output]

## Loaded Models
[paste ollama ps output]

## Disk Usage
[paste df -h output]

## Memory
[paste free -h output]

## Service Status
[paste systemctl status output]

## Recent Errors (Ollama)
[paste error log excerpt]

## Recent Errors (Open WebUI)
[paste error log excerpt]

## Validation
[paste validate-local-llm.sh output]

Please generate a structured weekly evaluation report with:
1. Health summary
2. Resource utilization observations
3. Issues found (if any)
4. Improvement proposals (ranked by priority)
5. Proposals that are safe to implement without operator review vs those that require review
```

## Report Format

The Evaluator should produce a report in this structure:

```markdown
# Weekly Evaluation Report — [DATE]

## Health Summary
[Pass / Partial / Fail with brief reason]

## Resource Utilization
[GPU, RAM, Disk observations]

## Issues Found
[List of issues, or "None"]

## Improvement Proposals

### Priority 1 — [Description]
- Rationale: ...
- Risk: Low / Medium / High
- Requires operator approval: Yes / No

### Priority 2 — [Description]
...

## Notes
[Any other observations]
```

## Acting on Proposals

1. Review each proposal from the Evaluator report.
2. For low-risk proposals (e.g., pull a newer model variant, update documentation): implement at operator discretion.
3. For medium-risk proposals (e.g., change GPU device list, update Ollama version): test in isolation first.
4. For high-risk proposals (e.g., change service architecture, update firewall rules): review carefully and schedule a maintenance window.
5. Never implement a proposal without reading it and understanding what it does.

## Automation Boundary

The Evaluator agent must never:

1. Execute commands on the Skippy host.
2. Modify service configurations directly.
3. Apply model changes without operator action.
4. Access credentials or API tokens.

If a future improvement adds automation for safe low-risk actions, define a strict allowlist and require explicit operator opt-in.

## Archiving Reports

Store weekly evaluation reports in a local directory or in this repository under a `reports/` folder if desired.

Suggested naming: `reports/eval-YYYY-MM-DD.md`
