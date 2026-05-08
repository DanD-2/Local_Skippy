# Z8 G4 Install Commands

## Purpose

Use this runbook when you are ready to execute the first Local_LLM deployment on the HP Z8 G4 from the Windows workspace.

This document translates the Local_LLM checklist into exact operator commands with a small number of values to replace.

For the current mixed-workstation path, apply these commands to an Ubuntu Studio 24.04 LTS install unless the creative software requirements force a different host OS.

## How To Use This File

Use this document when you are at the keyboard and want the exact commands in the right order.

Human rules:

1. Run one step at a time.
2. Do not keep pasting commands if a command fails and you do not understand why.
3. Confirm the GPU numbering before setting `LOCAL_LLM_GPU_DEVICES`.
4. Treat shared storage as optional and separate from the main Local_LLM runtime path.

## One-Screen Summary

1. Connect to the host and finish the base OS update.
2. Install the NVIDIA driver and record `nvidia-smi -L` output.
3. Install Docker and Ollama.
4. Copy `src/` helper files to the host.
5. Configure `/etc/default/local-llm`.
6. Apply the GPU policy.
7. Pull one model and test it.
8. Enable Open WebUI.
9. Run final validation.
10. Add the SMB share only if you still need it.

Current Skippy target values:

1. Host label: `Skippy`
2. FQDN: `Skippy.aybara.local`
3. IP: `192.168.128.5`
4. Admin user: `Daniel`
5. GPU posture: `2` GPUs for Local_LLM and `1` GPU reserved for workstation use
6. Storage posture: SSD 1 for OS and apps, SSD 2 for Local_LLM fast data, RAID10 HDD array for media storage
7. Shared storage: `\\192.168.128.6\Storage` with user `Daniel`

## Replace These Values First

Before running anything, replace these placeholders:

1. `<GPU_LIST>` with the actual two-GPU inference device list after validation, provisionally `1,2` until the live GPU ordering is confirmed.

If you want the shortest safe path, ignore Step 11 and Step 12 until the core Local_LLM service is already working.

Examples below assume you are running from the Local_LLM repository root on the Windows workstation.

## Step 1: Connect To The Fresh Ubuntu Host

From PowerShell:

```powershell
ssh Daniel@192.168.128.5
```

On the host, run:

```sh
hostnamectl
lsb_release -a
ip address
sudo apt update
sudo apt full-upgrade -y
sudo hostnamectl set-hostname Skippy
sudo reboot
```

If you want the Linux host to resolve its own FQDN locally, add a hosts entry such as:

```sh
echo '192.168.128.5 Skippy.aybara.local Skippy' | sudo tee -a /etc/hosts
```

If Ubuntu Studio was not installed from the initial media but the host is already on Ubuntu 24.04 Desktop, convert the workstation to the Studio toolset before continuing with creative-app validation:

```sh
sudo apt install -y ubuntustudio-installer
ubuntustudio-installer
```

Before continuing with Local_LLM install steps, apply the storage layout from `docs/storage-layout.md` so the machine is optimized for Local_LLM first and video editing second.

Keep the shared SMB path `\\192.168.128.6\Storage` out of the LLM hot path. Use it for shared transfers and collaboration only.

Reconnect after reboot:

```powershell
ssh Daniel@192.168.128.5
```

## Step 2: Install NVIDIA Driver And Validate GPUs

On the host, run:

```sh
lspci | grep -i nvidia
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot
```

Reconnect and validate:

```sh
nvidia-smi
nvidia-smi -L
```

Record the GPU numbering before you continue.

## Step 3: Install Docker And Ollama

On the host, run:

```sh
sudo apt install -y docker.io
sudo systemctl enable --now docker
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable --now ollama
sudo systemctl status docker --no-pager
systemctl status ollama --no-pager
```

For the current Ubuntu Studio workstation path, validate the creative stack before putting the LLM into daily use:

1. Read `docs/resolve-nvidia-prep.md` before sustained Resolve use.
2. Read `docs/cad-selection.md` before locking in the CAD workflow.

## Step 4: Copy Local_LLM Artifacts From The Workspace

From PowerShell in the Local_LLM repository root:

```powershell
scp "src/local-llm.env.example" "src/apply-ollama-gpu-policy.sh" "src/run-open-webui.sh" "src/local-llm-open-webui.service" "src/validate-local-llm.sh" Daniel@192.168.128.5:/tmp/
```

If you are running from a parent workspace instead of the Local_LLM repository root, adjust the paths accordingly.

## Step 5: Install The Artifacts On The Host

Reconnect or stay connected over SSH and run:

```sh
sudo install -m 644 /tmp/local-llm.env.example /etc/default/local-llm
sudo install -m 755 /tmp/apply-ollama-gpu-policy.sh /usr/local/bin/apply-ollama-gpu-policy.sh
sudo install -m 755 /tmp/run-open-webui.sh /usr/local/bin/local-llm-run-open-webui.sh
sudo install -m 755 /tmp/validate-local-llm.sh /usr/local/bin/validate-local-llm.sh
sudo install -m 644 /tmp/local-llm-open-webui.service /etc/systemd/system/local-llm-open-webui.service
```

## Step 6: Configure The Environment File

On the host, edit the Local_LLM environment file:

```sh
sudo nano /etc/default/local-llm
```

Set at least these values:

```dotenv
LOCAL_LLM_EXPECTED_GPUS=3
LOCAL_LLM_GPU_DEVICES=<GPU_LIST>
LOCAL_LLM_OLLAMA_HOST=127.0.0.1:11434
LOCAL_LLM_OLLAMA_BASE_URL=http://host.docker.internal:11434
LOCAL_LLM_WEBUI_PORT=3000
LOCAL_LLM_WEBUI_URL=http://127.0.0.1:3000
```

For the current Skippy plan, choose the two inference GPUs only. Do not expose the reserved workstation GPU to Ollama.

Until `nvidia-smi -L` proves otherwise, plan around `LOCAL_LLM_GPU_DEVICES=1,2` and reserve the remaining GPU for desktop and creative work.

## Step 7: Apply The Ollama GPU Policy

On the host, run:

```sh
sudo /usr/local/bin/apply-ollama-gpu-policy.sh
sudo systemctl daemon-reload
sudo systemctl restart ollama
systemctl show ollama --property=Environment
cat /etc/systemd/system/ollama.service.d/override.conf
```

## Step 8: Pull And Test The First Model

On the host, run:

```sh
ollama pull llama3.1:8b
ollama run llama3.1:8b "Respond with the word ready."
```

## Step 9: Enable Open WebUI

On the host, run:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now local-llm-open-webui.service
sudo systemctl status local-llm-open-webui.service --no-pager
sudo docker ps
curl -I http://127.0.0.1:3000
```

## Step 10: Run Final Validation

On the host, run:

```sh
sudo /usr/local/bin/validate-local-llm.sh
nvidia-smi
df -h
```

From another LAN machine, open:

```text
http://192.168.128.5:3000
```

## Step 11: Map The Shared Storage Drive If Needed

From PowerShell on the Windows operator system, map the shared storage drive without storing the password in the repo:

```powershell
$credential = Get-Credential -UserName "Daniel" -Message "Enter the password for \\192.168.128.6\Storage"
New-PSDrive -Name S -PSProvider FileSystem -Root "\\192.168.128.6\Storage" -Persist -Credential $credential
```

Alternative using `net use`:

```powershell
net use S: \\192.168.128.6\Storage /user:Daniel * /persistent:yes
```

Use the mapped drive for shared file movement, exports, and collaboration. Do not redirect `/var/lib/ollama`, `/var/lib/docker`, or other latency-sensitive runtime data to the network share.

## Step 12: Mount The Shared Storage On Ubuntu If Needed

If the Ubuntu workstation should also access the same share locally, mount it on the host after testing the Windows mapping.

Install CIFS support:

```sh
sudo apt install -y cifs-utils
sudo mkdir -p /mnt/storage
```

Create a root-owned credential file:

```sh
sudo nano /root/.smb-skippy-storage
sudo chmod 600 /root/.smb-skippy-storage
```

Credential file contents:

```ini
username=Daniel
password=<enter-password-here>
```

Mount the share manually first:

```sh
sudo mount -t cifs //192.168.128.6/Storage /mnt/storage -o credentials=/root/.smb-skippy-storage,uid=$(id -u Daniel),gid=$(id -g Daniel),iocharset=utf8,file_mode=0660,dir_mode=0770
df -h /mnt/storage
```

If the manual mount succeeds and you want it persistent, add this line to `/etc/fstab`:

```fstab
//192.168.128.6/Storage /mnt/storage cifs credentials=/root/.smb-skippy-storage,uid=1000,gid=1000,iocharset=utf8,file_mode=0660,dir_mode=0770,nofail,x-systemd.automount 0 0
```

Then validate:

```sh
sudo systemctl daemon-reload
sudo mount -a
df -h /mnt/storage
```

Use the Ubuntu mount for shared transfer and collaboration workflows only. Do not place `/var/lib/ollama`, `/var/lib/docker`, or active scratch data on the SMB path.

## Fast Failure Checks

If something is wrong, check these first:

1. `nvidia-smi` for driver and GPU visibility.
2. `systemctl status ollama --no-pager`
3. `systemctl status local-llm-open-webui.service --no-pager`
4. `sudo docker logs open-webui --tail 100`
5. `cat /etc/default/local-llm`
6. `cat /etc/systemd/system/ollama.service.d/override.conf`

## Creative Workstation Follow-Up

Before treating the build as complete for daily use:

1. Validate DaVinci Resolve using `docs/resolve-nvidia-prep.md`.
2. Validate the first CAD path using `docs/cad-selection.md`.
3. Keep the Ollama GPU reservation in place while the workstation is still being proven.
4. Run `docs/post-install-workstation-validation.md` before calling the mixed workstation ready.