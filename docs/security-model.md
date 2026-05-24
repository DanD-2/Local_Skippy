# Security Model

## Purpose

Define the security posture for the Local Skippy AI appliance: SSH-only admin access, LAN-restricted services, and safe credential handling.

## Summary

1. Admin access is SSH with key authentication only.
2. Open WebUI is LAN-accessible only by default.
3. No public internet exposure without an explicit deliberate change.
4. Credentials and API keys are never committed to this repository.
5. UFW firewall allows only required ports.

## SSH Hardening

### Key Authentication

1. Generate an SSH keypair on the admin machine if you do not already have one.
2. Copy the public key to the Skippy host.
3. Disable password authentication after key auth is confirmed working.

```sh
# On the admin machine
ssh-copy-id daniel@192.168.128.5

# On the Skippy host — after confirming key auth works
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### SSH Configuration

Edit `/etc/ssh/sshd_config` to enforce:

```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
X11Forwarding no
```

Restart SSH after changes:

```sh
sudo systemctl restart sshd
```

### Validation

```sh
ssh -o PasswordAuthentication=no daniel@192.168.128.5
```

This should succeed with the key and fail without it.

## Firewall (UFW)

### Required Ports

| Port | Service | Direction |
|---|---|---|
| 22 | SSH | Inbound from LAN |
| 3000 | Open WebUI | Inbound from LAN |
| 11434 | Ollama API | Inbound from LAN (optional — restrict if not needed by external tools) |

### UFW Setup

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 3000/tcp
# Only allow Ollama API from LAN if needed
# sudo ufw allow from 192.168.128.0/24 to any port 11434
sudo ufw enable
sudo ufw status
```

### Validation

```sh
sudo ufw status verbose
ss -tlnp | grep -E '22|3000|11434'
```

## LAN-Only Access

By default, all user-facing services are LAN-only:

1. Open WebUI on port 3000 is not reverse-proxied to the internet.
2. Ollama API on port 11434 is not publicly exposed.
3. SSH is LAN-accessible only unless you explicitly open it further.

To enable HTTPS or external access, add a reverse proxy (e.g., Nginx or Caddy) as an explicit optional layer. Do not enable public internet access without:

1. A reverse proxy with TLS termination.
2. Strong authentication on Open WebUI.
3. Firewall rules explicitly reviewed for the new exposure.

## Credential Handling

### Never commit credentials to this repository.

1. API keys for cloud AI providers go in `/etc/default/local-llm` or a separate secrets file outside the repository.
2. Proxmox API tokens go in `/etc/default/local-llm` or a separate file under `/etc/local-skippy/`.
3. SSH keys are never stored in the repository.

### Environment File Security

```sh
# Set correct permissions on the environment file
sudo chmod 600 /etc/default/local-llm
sudo chown root:root /etc/default/local-llm
```

Only root and explicitly authorized service accounts should read the environment file.

### Secrets File Pattern

If you need a separate secrets file:

```sh
sudo install -m 600 -o root -g root /dev/null /etc/local-skippy/secrets
# Edit the file with sudo and add key=value pairs
```

Reference it from the service by adding `EnvironmentFile=-/etc/local-skippy/secrets` to the systemd unit.

## Proxmox Access

See `docs/proxmox-integration.md` for the restricted token setup for the Infrastructure agent.

The core rule: the Infrastructure agent uses a **least-privilege API token**, not root credentials.

## Open WebUI Authentication

Open WebUI supports user accounts and authentication. Recommended:

1. Enable authentication on first setup.
2. Create separate accounts for each human user.
3. Do not leave the admin account with the default password.
4. Review Open WebUI's security documentation for the current version before production use.

## Validation Checklist

After setup, confirm:

1. SSH key auth works and password auth is disabled.
2. `ufw status` shows only required ports are open.
3. Open WebUI is not reachable from outside the LAN without deliberate configuration.
4. No credentials, tokens, or API keys appear in any committed repository file.
5. `/etc/default/local-llm` has `600` permissions and is owned by root.
