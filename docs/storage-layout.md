# Skippy Storage Layout

## Purpose

This document defines the storage layout for the Skippy dedicated AI server.  The host is
optimised for AI inference first.  There are no video editing or creative workstation workloads.

## Storage Inventory

| Device            | Type           | Size  | Role                          |
|-------------------|----------------|-------|-------------------------------|
| SSD 1             | HP FX900 Pro M.2| 1 TB  | Ubuntu Server OS and home     |
| SSD 2             | HP FX900 Pro M.2| 1 TB  | AI model and Docker data      |
| Remote LAN share  | SMB             | —     | Optional transfer share       |

Note: The four 1 TB HDDs previously attached as a RAID array are not used for AI inference
workloads.  They may be used for backup or log archiving if connected, but are not part of the
primary serving path.

## Design Priorities

1. AI model read speed comes first — all hot data on SSD.
2. OS stability comes second — keep model I/O off the OS disk.
3. Capacity is less important than latency and throughput.
4. No creative media storage is needed on this server.

## Recommended Mount Layout

| Mount point        | Device  | Contents                              |
|--------------------|---------|---------------------------------------|
| `/`                | SSD 1   | Ubuntu Server OS, packages, home dirs |
| `/var/lib/ollama`  | SSD 2   | Ollama model files                    |
| `/var/lib/docker`  | SSD 2   | Docker images and volumes (Open WebUI)|
| `/var/log/skippy`  | SSD 1   | Evaluation reports and action log     |

### Implementation

Partition SSD 2 as a single ext4 partition.  Mount it at `/data` and create symlinks:

```bash
sudo mkfs.ext4 /dev/nvme1n1p1
echo '/dev/nvme1n1p1 /data ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab
sudo mount /data
sudo mkdir -p /data/ollama /data/docker
sudo ln -s /data/ollama /var/lib/ollama
sudo ln -s /data/docker /var/lib/docker
```

Verify after reboot:

```bash
df -h /var/lib/ollama /var/lib/docker
```

Both should show SSD 2 as the backing device.

## Model Storage Estimate

| Agent model                              | Approx size |
|------------------------------------------|-------------|
| `nous-hermes2:34b-q4_K_M`               | ~20 GB      |
| `nous-hermes2:13b-q4_K_M`               | ~8 GB       |
| `nous-hermes2-mixtral:8x7b-q4_K_M`      | ~26 GB      |
| Open WebUI Docker image and volumes      | ~5 GB       |
| **Total**                                | **~59 GB**  |

SSD 2 at 1 TB provides substantial room for model growth and Docker data.

## Remote LAN Share (Optional)

The SMB share at `\\192.168.128.6\Storage` may be used for:

- Backup of evaluation reports.
- Transferring configuration files during initial setup.

Do **not** use it for:

- `/var/lib/ollama` — too slow for model I/O.
- `/var/lib/docker` — Docker requires local filesystem semantics.

If mounting persistently on Ubuntu:

```bash
# Store credentials in a root-only file — never in repo docs:
sudo install -m 600 -o root /dev/null /root/.smbcredentials
echo "username=<smb-user>" | sudo tee /root/.smbcredentials
echo "password=<smb-password>" | sudo tee -a /root/.smbcredentials
echo "//192.168.128.6/Storage /mnt/storage cifs credentials=/root/.smbcredentials,uid=daniel,gid=daniel,iocharset=utf8 0 0" \
  | sudo tee -a /etc/fstab
sudo mount /mnt/storage
```

## Success Criteria

The storage layout is correct when:

1. `df -h /var/lib/ollama` shows SSD 2 as the backing device.
2. `df -h /var/lib/docker` shows SSD 2 as the backing device.
3. The OS SSD (`/`) has at least 50 GB free after install.
4. `ollama pull nous-hermes2:34b-q4_K_M` completes without a disk-full error.
5. Open WebUI data volume is on SSD 2 (`docker volume inspect open-webui`).