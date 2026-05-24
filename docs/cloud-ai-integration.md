# Cloud AI Integration

## Purpose

This document defines how to optionally connect the Local Skippy agents to online AI services when local models are insufficient for a task.

Local-first is the default. Cloud AI is opt-in per agent.

## When to Use Cloud AI

| Situation | Recommendation |
|---|---|
| Task requires a model larger than available VRAM | Consider cloud fallback |
| Task requires real-time web search or current data | Cloud AI with search tools |
| Local model performance is consistently inadequate | Evaluate cloud model |
| Privacy-sensitive financial data | Prefer local model only |

## Recommended Cloud AI Providers By Agent

### Finance Agent

| Provider | Model | Notes |
|---|---|---|
| OpenAI | `gpt-4o` | Strong financial reasoning |
| Anthropic | `claude-opus-4-5` | Reliable structured analysis |
| Google | `gemini-2.5-pro` | Good for data processing |

**Privacy note:** Do not send sensitive personal or financial data to cloud providers unless you have reviewed and accepted the provider's data handling and retention policies.

### Infrastructure Agent

| Provider | Model | Notes |
|---|---|---|
| OpenAI | `gpt-4o` | Strong tool use and code generation |
| Anthropic | `claude-opus-4-5` | Reliable for infrastructure planning |

### Software Engineering Agent

| Provider | Model | Notes |
|---|---|---|
| OpenAI | `gpt-4o` | Strong code generation |
| Anthropic | `claude-opus-4-5` | Strong for code review and architecture |
| OpenAI | `o3` | Good for complex algorithmic problems |

### Evaluator Agent

| Provider | Model | Notes |
|---|---|---|
| OpenAI | `gpt-4o` | Structured report generation |
| Anthropic | `claude-opus-4-5` | Analysis and summarization |

## Configuration

### Open WebUI Cloud Connections

Open WebUI supports OpenAI-compatible API endpoints natively.

To add a cloud provider:

1. Open Open WebUI settings.
2. Navigate to **Connections** or **External Models**.
3. Add the provider's API base URL and API key.
4. The model will appear alongside local Ollama models.

### Environment File

Store API keys in the environment file:

```sh
# /etc/default/local-llm
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

Set permissions:

```sh
sudo chmod 600 /etc/default/local-llm
sudo chown root:root /etc/default/local-llm
```

**Never commit API keys to this repository.**

### API Base URLs

| Provider | API Base URL |
|---|---|
| OpenAI | `https://api.openai.com/v1` |
| Anthropic | `https://api.anthropic.com/v1` (via OpenAI-compatible wrapper or native) |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta` |

## Local-First Fallback Pattern

1. Each agent uses its local Hermes model by default.
2. If the local model fails or is insufficient, the operator manually selects the cloud model in Open WebUI.
3. Do not configure cloud models as the default for any agent unless you explicitly accept the cost and data-routing implications.

## Cost and Privacy Considerations

1. Cloud AI usage incurs API costs per token. Monitor usage in the provider dashboard.
2. Review each provider's data retention and training policies before routing sensitive content.
3. Financial data should default to local-only unless the operator has reviewed and accepted the provider's data policy.
4. Proxmox credentials and host secrets must never be sent to cloud AI providers.

## Egress Firewall Consideration

By default, the Skippy host allows outbound connections. If you want to restrict which external AI endpoints are reachable:

```sh
# Allow only OpenAI
sudo ufw allow out to any port 443 proto tcp
# Or restrict outbound by destination IP range if desired
```

Discuss with the Infrastructure agent if you want stricter egress controls.
