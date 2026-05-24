# Model Recommendations — Local and Online Models Per Agent

## Decision Framework

Choose models based on three factors:

1. **Task type** — financial analysis, infrastructure scripting, code generation, evaluation.
2. **Privacy requirement** — financial and infrastructure data should prefer local models.
3. **Capability need** — for complex reasoning or very large context, online models may be better.

The default for all agents is **local-first**.  Online models are opt-in.

---

## Agent 1 — Finance

### Primary recommendation: `nous-hermes2:34b-q4_K_M` (local)

NousResearch Hermes2 at 34B parameters with Q4_K_M quantization provides strong financial
reasoning, structured output, and instruction-following within the 24 GB VRAM budget (with
minor RAM overflow).

```bash
ollama pull nous-hermes2:34b-q4_K_M
```

VRAM estimate: ~20 GB (uses all three GPUs via tensor parallelism or layer distribution).

### Alternative local: `nous-hermes2:13b-q4_K_M`

Use the 13B variant if the 34B model causes too much contention with other agents.  Lower
quality but fits entirely within ~8 GB (one GPU).

```bash
ollama pull nous-hermes2:13b-q4_K_M
```

### Online option: `claude-3-5-sonnet-20241022` (Anthropic)

Best for:
- Analysing long financial documents (200K token context window).
- Complex multi-step financial modelling.
- Tasks where the local 34B quality is insufficient.

Configure via `docs/online-ai-providers.md`.

### Online option: `gpt-4o` (OpenAI)

Best for:
- Structured financial output (JSON, tables, charts via code interpreter).
- Cross-referencing multiple data sources.

### Summary table

| Model                      | Type   | VRAM   | Best for                           |
|----------------------------|--------|--------|------------------------------------|
| `nous-hermes2:34b-q4_K_M`  | Local  | ~20 GB | Default; balanced quality and privacy|
| `nous-hermes2:13b-q4_K_M`  | Local  | ~8 GB  | Fallback when VRAM is contended    |
| `claude-3-5-sonnet`        | Online | —      | Long documents, deep analysis      |
| `gpt-4o`                   | Online | —      | Structured output, data-heavy tasks|

---

## Agent 2 — Infrastructure

### Primary recommendation: `nous-hermes2:13b-q4_K_M` (local)

The 13B Hermes2 model is strong at infrastructure scripting, Ansible YAML, shell commands,
and systemd/Proxmox configuration generation.  It fits on a single GPU, leaving remaining
VRAM for the Finance agent.

```bash
ollama pull nous-hermes2:13b-q4_K_M
```

### Alternative local: `nous-hermes2:7b-q4_K_M`

Use the 7B variant if simultaneous multi-agent load on GPU is a concern.

```bash
ollama pull nous-hermes2:7b-q4_K_M
```

VRAM estimate: ~4.5 GB.

### Online option: `gpt-4o-mini` (OpenAI)

Cost-effective for routine infrastructure queries.  Avoid sending real server IPs, credentials,
or sensitive configuration details to external providers.

### Summary table

| Model                      | Type   | VRAM   | Best for                           |
|----------------------------|--------|--------|------------------------------------|
| `nous-hermes2:13b-q4_K_M`  | Local  | ~8 GB  | Default; shell/YAML/infra scripting|
| `nous-hermes2:7b-q4_K_M`   | Local  | ~4.5 GB| Low-VRAM fallback                  |
| `gpt-4o-mini`              | Online | —      | Quick infrastructure lookups       |

---

## Agent 3 — Software Engineering

### Primary recommendation: `nous-hermes2-mixtral:8x7b-q4_K_M` (local)

The Hermes2 Mixtral (8×7B MoE) model provides strong multi-language code generation and
reasoning.  The mixture-of-experts architecture gives near-70B reasoning quality at lower
inference cost.

```bash
ollama pull nous-hermes2-mixtral:8x7b-q4_K_M
```

VRAM estimate: ~26 GB (overflows ~2 GB to RAM with all three GPUs).

### Alternative local: `nous-hermes2:13b-q4_K_M`

If VRAM contention is a problem, fall back to the 13B model for most coding tasks.

### Alternative local: `deepseek-coder-v2:16b-lite-instruct-q4_K_M`

DeepSeek Coder v2 is a strong coding-specific model.  Use it if raw code generation quality
is more important than instruction following.

```bash
ollama pull deepseek-coder-v2:16b-lite-instruct-q4_K_M
```

### Online option: `gpt-4o` or `claude-3-5-sonnet`

For complex debugging, large codebase refactoring, or where a very large context window
(128K+ tokens) is needed to hold the full codebase context.

### Summary table

| Model                                  | Type   | VRAM    | Best for                          |
|----------------------------------------|--------|---------|-----------------------------------|
| `nous-hermes2-mixtral:8x7b-q4_K_M`    | Local  | ~26 GB  | Default; strong code+reasoning    |
| `nous-hermes2:13b-q4_K_M`             | Local  | ~8 GB   | Fallback under VRAM pressure      |
| `deepseek-coder-v2:16b-lite-instruct` | Local  | ~10 GB  | Focused code generation           |
| `gpt-4o`                              | Online | —       | Complex debugging, large context  |
| `claude-3-5-sonnet`                   | Online | —       | Large codebase analysis           |

---

## Agent 4 — Evaluator

### Primary recommendation: `nous-hermes2:13b-q4_K_M` (local)

The Evaluator runs on a weekly schedule and analyses structured log data.  The 13B Hermes2
model is sufficient for this task and shares the same model instance used by the
Infrastructure agent, minimising VRAM overhead.

```bash
# No additional pull needed if Infrastructure agent already pulled this model.
ollama list | grep nous-hermes2:13b-q4_K_M
```

### Online option: `gpt-4o-mini`

For richer natural-language evaluation summaries, `gpt-4o-mini` provides higher quality at
low cost.  Since the Evaluator handles non-sensitive operational logs (no financial data,
no credentials), the data-residency risk is lower.

### Summary table

| Model                      | Type   | VRAM   | Best for                              |
|----------------------------|--------|--------|---------------------------------------|
| `nous-hermes2:13b-q4_K_M`  | Local  | ~8 GB  | Default; log summarisation, analysis  |
| `gpt-4o-mini`              | Online | —      | Richer weekly report narratives       |

---

## Model Pull Reference (All Agents)

```bash
# Pull all default local agent models:
ollama pull nous-hermes2:34b-q4_K_M         # Finance (primary)
ollama pull nous-hermes2:13b-q4_K_M         # Infrastructure, Evaluator
ollama pull nous-hermes2-mixtral:8x7b-q4_K_M # Software Engineering

# Optional coding-focused alternative:
ollama pull deepseek-coder-v2:16b-lite-instruct-q4_K_M
```

Total VRAM if all models loaded simultaneously: ~20+8+26 = 54 GB — overflow to RAM required.
In practice, only the Finance model stays resident; others load on demand.

---

## Ollama Model Tags and Updates

Hermes models on Ollama are tagged by NousResearch.  Check for newer versions periodically:

```bash
# Check available tags for a model family:
ollama list
# Pull a newer version when available:
ollama pull nous-hermes2:latest
```

The Evaluator agent's weekly review script checks for model updates and reports them.
