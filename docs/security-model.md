# Security Model — SSH, Firewall, API Keys, and Agent Boundaries

## Principles

1. **LAN-first** — nothing is exposed to the internet by default.
2. **No plaintext secrets in the repository** — API keys and tokens are stored only in
   `/etc/default/skippy` with restricted file permissions.
3. **SSH key-only admin** — password auth for SSH is disabled.
4. **Least privilege** — agents and API tokens have only the access they need.
5. **Audit trail** — significant agent actions are logged.

---

## SSH Hardening

### Recommended `/etc/ssh/sshd_config` settings

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers daniel
X11Forwarding no
AllowTcpForwarding yes        # required for VS Code Remote SSH port forwarding
MaxAuthTries 3
LoginGraceTime 30
```

Apply and reload:

```bash
sudo sshd -t && sudo systemctl reload ssh
```

### Operator key setup

```bash
# On the admin workstation:
ssh-keygen -t ed25519 -C "skippy-admin" -f ~/.ssh/skippy_ed25519
ssh-copy-id -i ~/.ssh/skippy_ed25519.pub daniel@skippy.aybara.local
```

After confirming key login works, disable password auth as above.

---

## Firewall Baseline

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.128.0/24 to any port 22 proto tcp comment 'SSH LAN only'
sudo ufw allow from 192.168.128.0/24 to any port 3000 proto tcp comment 'Open WebUI LAN only'
sudo ufw enable
```

Scope SSH and WebUI to your LAN subnet rather than all interfaces for a tighter posture.

---

## Environment File and Secret Storage

All runtime secrets are stored in `/etc/default/skippy`.

### File permissions

```bash
sudo install -m 640 -o root -g ollama src/skippy.env.example /etc/default/skippy
# Then edit /etc/default/skippy and fill in real values.
```

### What goes in `/etc/default/skippy`

- GPU device assignments.
- Ollama and Open WebUI configuration.
- Proxmox API token (for Infrastructure agent).
- Online AI provider API keys (if used).
- SMTP credentials for weekly evaluation email (if used).

### What never goes in this repository

- Real API keys.
- Real Proxmox tokens.
- Passwords of any kind.
- Any credential that gives access to a real system or account.

Use `src/skippy.env.example` as the template — it contains only placeholder values surrounded by
`<angle brackets>`.

---

## Online AI Provider API Keys

If you enable online AI providers (OpenAI, Anthropic, Google Gemini), store the API keys in
`/etc/default/skippy` under the variable names shown in `docs/online-ai-providers.md`.

Do **not**:

- Paste API keys into the Open WebUI chat interface.
- Store API keys in any file tracked by this repository.
- Share API keys in chat, email, or log files.

Open WebUI reads provider configuration from its own settings database, which is stored in the
`open-webui` Docker volume on SSD 2 — not in this repository.

---

## Proxmox Token Security

The Infrastructure agent Proxmox API token must be:

1. Created as a dedicated token user in Proxmox with minimum required permissions.
2. Stored only in `/etc/default/skippy` under `SKIPPY_PROXMOX_TOKEN`.
3. Never committed to this repository.
4. Rotated if there is any suspicion of exposure.

See `docs/proxmox-integration.md` for the minimum Proxmox permission set.

---

## Open WebUI User Accounts

Open WebUI requires user accounts for agent access.  Operator responsibilities:

1. Create individual accounts for each human user — do not share a single account.
2. Use strong passwords; Open WebUI does not support SSO in the default configuration.
3. The first registered account automatically becomes admin — register the admin account
   before any other user.
4. Disable public registration after initial user setup.

---

## Agent Execution Boundaries

| Agent               | Can access host shell? | Can run OS commands? | Network access              |
|---------------------|------------------------|----------------------|-----------------------------|
| Finance             | No                     | No                   | LAN (Open WebUI)            |
| Infrastructure      | No (generates scripts) | No (operator runs)   | LAN + outbound to Proxmox   |
| Software Engineering| Via SSH user context   | As SSH user only     | LAN + SSH port forwards     |
| Evaluator           | Via weekly-review.sh   | Defined safe list only| LAN only                   |

---

## Audit Log

The file `/var/log/skippy/agent-actions.log` records:

- Evaluator auto-actions with timestamp, action taken, and result.
- Any manual operator command run in response to an agent proposal.

The Evaluator agent includes this log in its weekly evaluation report.

Log rotation is managed by `logrotate` — the Evaluator agent may trigger rotation as an
auto-action.

---

## Threat Model Notes

This deployment assumes:

- The LAN is trusted for access-control purposes.
- Physical access to the server is restricted (data-centre or locked room).
- The Skippy host is not multi-tenant — only the operator and a small number of known LAN users
  have access.

Additional hardening (fail2ban, auditd, AppArmor profiles) is not required for the baseline
but is documented in `docs/operations.md` as optional phase-2 steps.
