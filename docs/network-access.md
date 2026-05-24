# Network Access — Ports, Firewall, and Remote Entry Points

## Default Network Posture

Local Skippy is **LAN-only by default**.  No services are exposed to the internet without a
deliberate operator decision.

## Host Network Identity

| Field       | Value                     |
|-------------|---------------------------|
| Hostname    | `skippy.aybara.local`     |
| IP address  | `192.168.128.5`           |
| DNS scope   | LAN only                  |

## Open Ports (default install)

| Port | Protocol | Service         | Source allowed  |
|------|----------|-----------------|-----------------|
| 22   | TCP      | SSH admin        | LAN only        |
| 3000 | TCP      | Open WebUI       | LAN only        |

## Ports Intentionally Not Exposed to LAN

| Port  | Service          | Why not exposed                                |
|-------|------------------|------------------------------------------------|
| 11434 | Ollama API       | Internal use only; Open WebUI talks to it locally|

If you need Ollama API access from external tools (e.g. VS Code Continue extension on a remote
device), use SSH port forwarding instead of opening port 11434 to the LAN:

```bash
# On the remote developer device:
ssh -L 11434:127.0.0.1:11434 daniel@skippy.aybara.local
# Then point VS Code Continue at http://127.0.0.1:11434
```

## Firewall Configuration

The recommended firewall is `ufw`.  Apply these rules after the Ubuntu Server install:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH admin'
sudo ufw allow 3000/tcp comment 'Open WebUI'
sudo ufw enable
sudo ufw status verbose
```

After enabling, confirm the rule set matches the intended open-port table above.

## Access Methods

### Browser — Open WebUI

All human-facing agent interaction happens through Open WebUI.

- URL: `http://skippy.aybara.local:3000`
- Authentication: Open WebUI user accounts managed by the operator.
- Encryption: plain HTTP by default on the LAN.  Add HTTPS via reverse proxy if needed.

### SSH — Admin Access

All operator administration uses SSH.

```bash
ssh daniel@skippy.aybara.local
```

Key-based authentication is required; password authentication should be disabled.
See `docs/security-model.md` for SSH hardening steps.

### VS Code Remote SSH — Software Engineering Agent

The Software Engineering agent workspace is accessed from VS Code on a separate developer device.

1. Install the **Remote - SSH** extension in VS Code.
2. Add `skippy.aybara.local` to your SSH config (`~/.ssh/config`).
3. Connect via **Remote Explorer → SSH Targets → skippy.aybara.local**.
4. Open the workspace in the desired project directory on the host.

See `docs/vscode-integration.md` for detailed configuration.

### Proxmox — Infrastructure Agent

The Infrastructure agent communicates with the separate Proxmox host via its web API.  No direct
port on Skippy is opened for this; the agent makes outbound HTTPS calls to the Proxmox host.

See `docs/proxmox-integration.md` for the API token and access control setup.

## Optional: Reverse Proxy and HTTPS

If you want named HTTPS access (e.g. `https://skippy.aybara.local`), add a reverse proxy on the
LAN.  The simplest approach is Nginx Proxy Manager or Caddy on a separate LAN host.

Basic Nginx reverse proxy snippet for HTTPS termination:

```nginx
server {
    listen 443 ssl;
    server_name skippy.aybara.local;

    ssl_certificate     /etc/ssl/certs/skippy.crt;
    ssl_certificate_key /etc/ssl/private/skippy.key;

    location / {
        proxy_pass http://192.168.128.5:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

If you add HTTPS via reverse proxy:

1. Update `ufw` to allow port 443 (or restrict to the reverse-proxy host IP only).
2. Do not expose port 3000 directly once HTTPS is working.
3. Consider whether Ollama API exposure through the reverse proxy is actually needed before
   opening it.

## Online AI Provider Traffic

When online AI providers are configured (see `docs/online-ai-providers.md`), Open WebUI makes
outbound HTTPS calls to those providers.  No inbound ports are required.  Ensure outbound HTTPS
(port 443) is allowed in your LAN router/firewall for the Skippy host IP.
