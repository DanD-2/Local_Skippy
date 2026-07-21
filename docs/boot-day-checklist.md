# Boot-Day Checklist

## Purpose

Use this checklist at the machine while booting and installing the first Ubuntu Server 26.04 Local_LLM build on Skippy.

This is the short operator path. For the full rationale, use `docs/start-here.md` and `docs/ubuntu-server-26.04-install-runbook.md`.

## Step 1: Confirm The Plan

Before powering on the installer, confirm these values:

1. Hostname: `Skippy`
2. FQDN: `Skippy.aybara.local`
3. Target IP: `192.168.128.5`
4. Admin user: `daniel`
5. GPU mode: all `3` RTX 4060 devices available to Local_LLM by default
6. Storage layout: SSD 1 for OS, SSD 2 for `/var/lib/ollama` and `/var/lib/docker`, RAID10 HDD for `/srv/media`

## Step 2: Boot The Ubuntu Server 26.04 Installer

At the firmware or boot menu:

1. Confirm UEFI mode.
2. Boot from the Ubuntu Server 26.04 installer media.
3. Choose the normal server install path.
4. Enable OpenSSH Server during setup.

## Step 3: Create The Admin User

During installer identity setup:

1. Set the host name to `Skippy`.
2. Create the administrative user as `daniel`.
3. Enter the password interactively at the installer prompt.
4. Keep this account in the default administrator path so it has `sudo` access.

Operator note:

Do not store the account password in this repository or any other plaintext runbook.

## Step 4: Apply The Disk Layout

During storage setup:

1. Put `/` on SSD 1.
2. Reserve SSD 2 for Local_LLM hot data.
3. Leave the RAID10 HDD array for `/srv/media` or other bulk non-hot data.
4. Do not place `/var/lib/ollama` or `/var/lib/docker` on the HDD array or SMB share.

## Step 5: Finish The Base Install

Before first reboot:

1. Confirm the network path is correct.
2. Confirm OpenSSH is selected.
3. Confirm the installer will finish with the `daniel` administrative account.
4. Remove the installer media when prompted.

## Step 6: First Login

After the first boot:

1. Log in as `daniel`.
2. Confirm the host name and IP.
3. Continue with `docs/z8g4-install-commands.md`.

## Stop Rules

Stop and fix the current step before moving on if:

1. The installer is not in UEFI mode.
2. OpenSSH was not selected.
3. The wrong host name or admin user was entered.
4. The disk plan drifted from the SSD-first layout.
