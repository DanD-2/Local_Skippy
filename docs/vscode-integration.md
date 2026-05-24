# VS Code Integration — Software Engineering Agent Remote Access

## Overview

The Software Engineering agent is the primary agent for code-centric workflows.  Developers on
a separate device connect to the Skippy host via VS Code Remote SSH, then interact with the
agent through either:

1. **Open WebUI** in a browser for conversational code assistance.
2. **VS Code Continue extension** pointed at Ollama for inline AI code completion and chat.

---

## Prerequisites

On the developer device:

- VS Code with the **Remote - SSH** extension installed.
- SSH key pair configured for `skippy.aybara.local`.
- (Optional) VS Code **Continue** extension for inline AI coding assistance.

On Skippy:

- SSH server running and accessible on port 22.
- Ollama running with the Software Engineering agent model loaded.
- Open WebUI running on port 3000.

---

## SSH Configuration

On the developer device, add Skippy to your SSH config:

```
# ~/.ssh/config

Host skippy
    HostName skippy.aybara.local
    User daniel
    IdentityFile ~/.ssh/skippy_ed25519
    ForwardAgent no
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Test the connection:

```bash
ssh skippy
```

---

## VS Code Remote SSH Setup

1. Open VS Code.
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) → **Remote-SSH: Connect to Host**.
3. Select `skippy` from the list (or enter `daniel@skippy.aybara.local`).
4. A new VS Code window opens with the remote session.
5. Navigate to your project directory on Skippy using the Explorer panel.

### Recommended VS Code extensions to install on the remote host

Install these in the remote VS Code session (they run server-side on Skippy):

- **Continue** — AI coding assistant backed by Ollama.
- **GitLens** — enhanced Git history and blame.
- **Python** / **Go** / **Rust Analyzer** etc. as appropriate for the project language.

---

## Continue Extension Configuration

The VS Code Continue extension can use the local Ollama instance on Skippy for inline code
assistance without sending code to external services.

### Configure Continue to use local Ollama

Edit `~/.continue/config.json` on the remote session:

```json
{
  "models": [
    {
      "title": "SoftwareEng — Hermes Mixtral",
      "provider": "ollama",
      "model": "nous-hermes2-mixtral:8x7b-q4_K_M",
      "apiBase": "http://127.0.0.1:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "SoftwareEng Autocomplete",
    "provider": "ollama",
    "model": "nous-hermes2-mixtral:8x7b-q4_K_M",
    "apiBase": "http://127.0.0.1:11434"
  }
}
```

Since VS Code Remote SSH runs the Continue extension server-side on Skippy, it reaches Ollama
on `127.0.0.1:11434` without any port forwarding.

### Using an online model with Continue

If you want to use an online provider through Continue:

```json
{
  "models": [
    {
      "title": "GPT-4o (online)",
      "provider": "openai",
      "model": "gpt-4o",
      "apiKey": "${OPENAI_API_KEY}"
    }
  ]
}
```

`${OPENAI_API_KEY}` reads from the shell environment.  Source `/etc/default/skippy` in your
remote `.bashrc` or `.profile` to make this available:

```bash
# In ~/.bashrc on Skippy:
if [ -f /etc/default/skippy ]; then
    # Export only the API key variables, not credentials:
    export OPENAI_API_KEY=$(grep ^OPENAI_API_KEY /etc/default/skippy | cut -d= -f2-)
fi
```

**Do not export Proxmox tokens or other unrelated secrets from this block.**

---

## Accessing Ollama API from the Developer Device (Port Forwarding)

If you want to use Ollama directly from VS Code running locally (not via Remote SSH), use SSH
port forwarding:

```bash
# On the developer device — forward local port 11434 to Ollama on Skippy:
ssh -L 11434:127.0.0.1:11434 skippy -N
```

Then configure Continue or any other tool on the local device to use
`http://127.0.0.1:11434` as the Ollama API base URL.

---

## Workspace Guidelines

1. Keep project source code in the developer user's home directory on Skippy
   (e.g. `/home/daniel/projects/`).
2. Do not store source code in `/etc/default/`, `/var/`, or other system paths.
3. The Software Engineering agent should not have access to `/etc/default/skippy` or other
   credential files.
4. Use standard Unix file permissions to separate user workspace from system config.

---

## Latency Note

VS Code Remote SSH over a LAN connection has excellent performance.  Code editing, terminal use,
and AI inference should all feel responsive over a gigabit LAN connection to Skippy.
