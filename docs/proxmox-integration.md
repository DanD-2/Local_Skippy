# Proxmox Integration — Infrastructure Agent Access Policy

## Purpose

The Infrastructure agent on Local Skippy has controlled access to a separate, dedicated Proxmox
host.  This document defines the access model, credential handling, and approved action scope.

---

## Proxmox Host Context

| Field          | Value                            |
|----------------|----------------------------------|
| Role           | Dedicated Proxmox host           |
| Services       | Free Proxmox services (LXC/VM)   |
| Network access | LAN-reachable from Skippy        |
| Admin user     | Separate from Skippy             |

The Proxmox host is a separate physical device.  Skippy's Infrastructure agent interacts with
it via the Proxmox API — it does not have SSH access to the Proxmox host itself.

---

## Credential Design

### API Token Approach

The Infrastructure agent uses a **dedicated Proxmox API token** rather than username/password
authentication.  This provides:

- Token-scoped privileges (not full admin access).
- Revocability without changing the admin password.
- No password storage in environment files.

### Creating the API Token in Proxmox

1. Log in to the Proxmox web UI.
2. Navigate to **Datacenter → Permissions → API Tokens**.
3. Click **Add**.
4. Set:
   - User: create a dedicated user `skippy-infra@pve` or use an existing limited user.
   - Token ID: `skippy-agent`.
   - Privilege Separation: **enabled** (token has independent ACL).
5. Copy the token secret — it is shown only once.
6. Configure ACLs for the token user to allow only the required permissions (see below).

### Minimum Required Proxmox Permissions

| Proxmox Privilege      | Why needed                                   |
|------------------------|----------------------------------------------|
| `VM.Audit`             | Read VM/CT status                            |
| `VM.PowerMgmt`         | Start/stop VMs and containers                |
| `Datastore.Audit`      | Read storage usage                           |
| `Sys.Audit`            | Read node status                             |

Do **not** grant:

- `VM.Allocate` (create/delete VMs) — unless explicitly approved by the operator.
- `Sys.Modify` — covers dangerous node-level changes.
- `Permissions.Modify` — prevents privilege escalation.

### Storing the Token on Skippy

Store the Proxmox token in `/etc/default/skippy`:

```bash
# Proxmox API access for Infrastructure agent
SKIPPY_PROXMOX_HOST=https://192.168.128.X:8006    # replace with Proxmox host IP
SKIPPY_PROXMOX_TOKEN_ID=skippy-infra@pve!skippy-agent
SKIPPY_PROXMOX_TOKEN_SECRET=<token-secret-here>
```

**Never commit real token values to this repository.**

Permissions on `/etc/default/skippy`:

```bash
sudo chmod 640 /etc/default/skippy
sudo chown root:ollama /etc/default/skippy
```

---

## Approved Agent Actions

The Infrastructure agent may assist with the following Proxmox actions:

### Always permitted (read-only)
- Query VM and container status.
- List available storage pools and usage.
- Read node health metrics.

### Permitted with operator confirmation in the chat
- Start or stop a VM or container.
- Resize a container disk (grow only).
- Create a new LXC container from an approved template.

### Requires separate operator Proxmox web UI action
- Deleting any VM or container.
- Changing network configuration.
- Creating or modifying user accounts or API tokens.
- Any action requiring `Sys.Modify` or `Permissions.Modify`.

---

## Using the Infrastructure Agent for Proxmox Tasks

The agent does not execute Proxmox API calls autonomously.  The workflow is:

1. Ask the Infrastructure agent to analyse a Proxmox task in Open WebUI.
2. The agent provides the API call sequence or Proxmox CLI/web UI steps required.
3. The operator reviews the proposed steps.
4. The operator executes the steps (either through the Proxmox web UI or via `pvesh` commands
   on the Proxmox host).

Example agent interaction:

> "What VMs are currently running on my Proxmox host?"

The agent will generate a `curl` command or `pvesh` command using the stored token variables,
which the operator then runs from a terminal.

---

## Proxmox Connection Validation

After setting up the token in `/etc/default/skippy`, validate the connection:

```bash
# Load env:
source /etc/default/skippy

# Query Proxmox node status:
curl -s -k \
  -H "Authorization: PVEAPIToken=${SKIPPY_PROXMOX_TOKEN_ID}=${SKIPPY_PROXMOX_TOKEN_SECRET}" \
  "${SKIPPY_PROXMOX_HOST}/api2/json/nodes" | python3 -m json.tool
```

A successful response returns a JSON array of Proxmox nodes.

---

## Security Notes

- The Proxmox API token is treated as a secret and stored only in `/etc/default/skippy`.
- Token values must never appear in chat conversations, log files, or this repository.
- Rotate the token immediately if there is any suspicion of exposure.
- The Infrastructure agent does not persist Proxmox credentials in its model context —
  they are loaded from the environment at runtime only.
- Log all Proxmox-related operator actions in `/var/log/skippy/agent-actions.log`.
