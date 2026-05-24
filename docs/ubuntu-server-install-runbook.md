# Ubuntu Server 24.04 LTS Install Runbook

## Purpose

This runbook covers a clean install of Ubuntu Server 24.04 LTS on the HP Z8 G4 as a dedicated
headless AI appliance.  No desktop packages are installed.

---

## Prerequisites

- Ubuntu Server 24.04 LTS ISO (download from ubuntu.com/download/server).
- USB boot drive (8 GB minimum, created with Rufus or `dd`).
- Physical or IPMI/iDRAC console access during install.
- SSH access from LAN after install.

---

## BIOS / UEFI Settings (HP Z8 G4)

Before booting the installer, confirm these BIOS settings:

1. Boot mode: **UEFI**.
2. Secure Boot: **Disabled** (required for NVIDIA driver installation).
3. Boot order: USB first, then SSD.
4. SATA controller: AHCI mode (not RAID unless you intend a hardware RAID set).
5. All three NVIDIA GPUs visible in BIOS.

---

## Installation Steps

### 1. Boot Ubuntu Server installer

Boot from the USB drive.  Select **Install Ubuntu Server** (not the "Try" option).

### 2. Language, keyboard, and locale

Select your language and keyboard layout.  For the locale, UTC timezone is recommended for a
server to keep logs unambiguous.

### 3. Network

Configure the primary NIC to use a **static IP** address:

| Field          | Value               |
|----------------|---------------------|
| IP address     | `192.168.128.5`     |
| Subnet         | `255.255.255.0`     |
| Gateway        | `192.168.128.1`     |
| DNS            | Your LAN DNS server |

### 4. Storage layout

| SSD | Mount point        | Filesystem | Notes                              |
|-----|--------------------|------------|------------------------------------|
| SSD 1 (OS)  | `/`          | ext4       | Ubuntu Server, all system files    |
| SSD 2 (Data)| `/var/lib/ollama` | ext4 | Ollama models (separate mount)    |
| SSD 2 (Data)| `/var/lib/docker`  | ext4 | Docker volumes                   |

Alternative: put `/var/lib/ollama` and `/var/lib/docker` on the same SSD 2 partition under
`/data` with symlinks.  The key goal is to keep model and Docker state off the OS SSD.

Recommended partition layout for SSD 2:

```
SSD 2
└── /data  (ext4, all remaining space)
    ├── /data/ollama   → symlinked from /var/lib/ollama
    └── /data/docker   → symlinked from /var/lib/docker
```

### 5. Profile setup

- Your name: Daniel
- Server name: `skippy`
- Username: `daniel`
- Password: strong, not shared; SSH key auth will replace password after install.

### 6. SSH

Enable **Install OpenSSH server** during the install wizard.  Optionally import your SSH key
from GitHub if prompted.

### 7. Snaps and additional packages

**Do not install any snap packages** during the wizard.  Keep the base install minimal.

### 8. Complete install and reboot

Let the installer finish, then remove the USB drive and reboot.

---

## Post-Install Steps

### 1. SSH in and update

```bash
ssh daniel@192.168.128.5
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
```

### 2. Set static hostname

```bash
sudo hostnamectl set-hostname skippy
echo "192.168.128.5 skippy skippy.aybara.local" | sudo tee -a /etc/hosts
```

### 3. Confirm storage mounts

```bash
df -h
lsblk
```

Confirm SSD 2 is mounted at `/data` (or the intended mount point).  Create symlinks if using
the `/data` layout:

```bash
sudo mkdir -p /data/ollama /data/docker
sudo ln -s /data/ollama /var/lib/ollama
sudo ln -s /data/docker /var/lib/docker
```

### 4. Install NVIDIA driver

```bash
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers install --gpgpu
# Or specify the driver version explicitly:
sudo apt install -y nvidia-driver-550-server
sudo reboot
```

After reboot, confirm all three GPUs are visible:

```bash
nvidia-smi
```

Expected output: three RTX 4060 devices listed.

### 5. Install Docker

```bash
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo usermod -aG docker daniel
sudo systemctl enable --now docker
```

Log out and back in for group membership to take effect, then verify:

```bash
docker run --rm hello-world
```

### 6. Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable --now ollama
```

Verify:

```bash
ollama --version
systemctl status ollama
```

### 7. Install NVIDIA Container Toolkit (for GPU access in Docker)

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 8. Configure firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.128.0/24 to any port 22 proto tcp comment 'SSH LAN only'
sudo ufw allow from 192.168.128.0/24 to any port 3000 proto tcp comment 'Open WebUI LAN only'
sudo ufw enable
sudo ufw status verbose
```

### 9. Deploy Local Skippy

```bash
# Install helper scripts:
sudo install -m 755 src/apply-ollama-gpu-policy.sh  /usr/local/bin/skippy-apply-gpu-policy.sh
sudo install -m 755 src/run-open-webui.sh            /usr/local/bin/local-llm-run-open-webui.sh
sudo install -m 755 src/validate-local-llm.sh        /usr/local/bin/skippy-validate.sh
sudo install -m 755 src/weekly-review.sh             /usr/local/bin/skippy-weekly-review.sh
sudo install -m 755 src/configure-agents.sh          /usr/local/bin/skippy-configure-agents.sh

# Copy and edit the environment file:
sudo install -m 640 -o root -g ollama src/skippy.env.example /etc/default/skippy
sudo nano /etc/default/skippy   # fill in values

# Apply GPU policy:
sudo skippy-apply-gpu-policy.sh
sudo systemctl daemon-reload && sudo systemctl restart ollama

# Deploy Open WebUI service:
sudo cp src/local-llm-open-webui.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now local-llm-open-webui

# Pull and configure all agent models:
sudo skippy-configure-agents.sh

# Validate:
sudo skippy-validate.sh
```

---

## First-Login Checklist After Full Deployment

- [ ] `nvidia-smi` shows all three RTX 4060 GPUs.
- [ ] `systemctl status ollama` shows active.
- [ ] `systemctl status local-llm-open-webui` shows active.
- [ ] `docker ps` shows `open-webui` container running.
- [ ] `ollama ps` shows Finance agent model loaded.
- [ ] Browser at `http://skippy.aybara.local:3000` shows Open WebUI login page.
- [ ] Create Open WebUI admin account (first registration becomes admin).
- [ ] Test Finance agent with a prompt.
- [ ] Run `sudo skippy-validate.sh` — reports success.
