# Online AI Providers — Optional External Model Integration

## Overview

Local Skippy uses local Ollama models by default.  Optionally, you can route agent conversations
through external AI providers (OpenAI, Anthropic, Google Gemini) when higher capability or
larger context windows are needed.

Open WebUI supports external providers natively through its **Model Management** settings.  No
code changes are required — configuration is done entirely in the Open WebUI admin panel and in
`/etc/default/skippy` for the API keys.

---

## Supported Providers

| Provider      | Models available                                    | Use case                         |
|---------------|-----------------------------------------------------|----------------------------------|
| OpenAI        | `gpt-4o`, `gpt-4o-mini`, `o1`, `o1-mini`           | Finance, Software Engineering    |
| Anthropic     | `claude-3-5-sonnet`, `claude-3-haiku`               | Finance, long-document analysis  |
| Google Gemini | `gemini-1.5-pro`, `gemini-1.5-flash`                | General, large context           |
| Groq          | `llama3-70b-8192`, `mixtral-8x7b-32768`             | Fast inference, Evaluator        |

---

## Security Requirements

### API Key Storage

API keys must **never** be committed to this repository.

Store API keys in `/etc/default/skippy` under the variable names below:

```bash
# OpenAI
OPENAI_API_KEY=<your-openai-key>

# Anthropic
ANTHROPIC_API_KEY=<your-anthropic-key>

# Google Gemini
GEMINI_API_KEY=<your-gemini-key>

# Groq
GROQ_API_KEY=<your-groq-key>
```

File permissions:

```bash
sudo chmod 640 /etc/default/skippy
sudo chown root:ollama /etc/default/skippy
```

### Network Controls

Online provider API calls are outbound HTTPS (port 443) from Skippy to the provider's endpoint.
No inbound ports are required.  Ensure your LAN router/firewall allows outbound HTTPS from
`192.168.128.5`.

**Do not route online AI traffic through a shared proxy** without understanding the data
residency implications for financial and infrastructure data.

### Data Residency Warning

Any prompt sent to an online provider leaves your LAN and is processed by a third party.

For the Finance agent: be particularly careful about what financial data is included in
prompts when using online models.  Sensitive financial figures, account numbers, or
proprietary business data should never be sent to external providers without an appropriate
data processing agreement.

For the Infrastructure agent: server IP addresses, credentials, and configuration details
should not be included in prompts to external providers.

---

## Configuring Providers in Open WebUI

### Step 1 — Store API keys in the environment file

Edit `/etc/default/skippy` and add the API key variables above.

### Step 2 — Restart Open WebUI to pick up env changes

```bash
sudo systemctl restart local-llm-open-webui
```

### Step 3 — Add the provider in Open WebUI admin settings

1. Log in as the admin user at `http://skippy.aybara.local:3000`.
2. Go to **Admin Panel → Settings → Connections**.
3. Under **OpenAI API**, enter:
   - API Base URL: `https://api.openai.com/v1`
   - API Key: paste your `OPENAI_API_KEY` value.
4. Click **Verify Connection**, then **Save**.
5. Repeat for Anthropic (base URL: `https://api.anthropic.com`).

For Google Gemini, use the OpenAI-compatible base URL:
`https://generativelanguage.googleapis.com/v1beta/openai/`

### Step 4 — Assign models to agent workspaces

In Open WebUI, each agent workspace can pin a default model.  Assign online models to the
agents where appropriate:

- Finance agent: pin `gpt-4o` or `claude-3-5-sonnet` as an alternative to the local default.
- Software Engineering: pin `gpt-4o` for complex refactoring tasks.
- Infrastructure and Evaluator: local models are usually sufficient; online is optional.

---

## Cost Management

Online AI providers charge per token.  To avoid unexpected costs:

1. Set usage limits in your provider dashboard (OpenAI, Anthropic, Google console).
2. Assign online models only to the agent workspaces that need them — not the default fallback.
3. Use `gpt-4o-mini` or `claude-3-haiku` for routine tasks; reserve `gpt-4o` or
   `claude-3-5-sonnet` for tasks that clearly need the larger model.
4. Review monthly API cost in the provider dashboard during the Evaluator's weekly report cycle.

---

## Provider Comparison for Each Agent

### Finance Agent

| Model                    | Type   | Strengths                                          |
|--------------------------|--------|----------------------------------------------------|
| `nous-hermes2:34b-q4_K_M`| Local  | No data leaves LAN; strong reasoning               |
| `gpt-4o`                 | Online | State-of-the-art reasoning; higher cost            |
| `claude-3-5-sonnet`      | Online | Excellent at long documents and financial analysis |

**Recommendation**: Use local Hermes2 34B for routine tasks.  Switch to `claude-3-5-sonnet`
for deep document analysis where a larger context window is critical.

### Infrastructure Agent

| Model                    | Type   | Strengths                                          |
|--------------------------|--------|----------------------------------------------------|
| `nous-hermes2:13b-q4_K_M`| Local  | Good at shell and config generation                |
| `gpt-4o-mini`            | Online | Fast, cost-effective for short infra tasks         |

**Recommendation**: Local model is sufficient for the majority of infrastructure tasks.

### Software Engineering Agent

| Model                          | Type   | Strengths                                    |
|--------------------------------|--------|----------------------------------------------|
| `nous-hermes2-mixtral:8x7b-q4_K_M` | Local | Strong code generation across languages  |
| `gpt-4o`                       | Online | Best-in-class code reasoning and debugging   |
| `claude-3-5-sonnet`            | Online | Excellent for large codebase analysis        |

**Recommendation**: Use local Mixtral for routine coding.  Use `gpt-4o` or `claude-3-5-sonnet`
for complex debugging or large codebase refactoring where context length matters.

### Evaluator Agent

| Model                    | Type   | Strengths                                          |
|--------------------------|--------|----------------------------------------------------|
| `nous-hermes2:13b-q4_K_M`| Local  | Cost-free; adequate for log summarization          |
| `gpt-4o-mini`            | Online | Good at structured analysis at low cost            |

**Recommendation**: Local model is the default.  `gpt-4o-mini` is a cost-effective online
alternative for richer evaluation summaries.

---

## Groq Integration (Optional Fast Inference)

Groq provides very fast token generation using their LPU hardware, often at lower cost than
OpenAI for equivalent models.  Useful for the Software Engineering agent when fast code
iteration is needed.

Configure in Open WebUI using the Groq OpenAI-compatible base URL:
`https://api.groq.com/openai/v1`

Add `GROQ_API_KEY` to `/etc/default/skippy` and configure the connection as an additional
OpenAI-compatible endpoint in Open WebUI admin settings.
