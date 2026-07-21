[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[A-Za-z]$')]
    [string]$UsbDriveLetter = 'D',

    [Parameter(Mandatory = $false)]
    [string]$Hostname = 'Skippy',

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = 'daniel',

    [Parameter(Mandatory = $true)]
    [string]$LinuxPasswordHash,

    [Parameter(Mandatory = $false)]
    [string]$Locale = 'en_US.UTF-8',

    [Parameter(Mandatory = $false)]
    [string]$KeyboardLayout = 'us',

    [Parameter(Mandatory = $false)]
    [string]$Timezone = 'UTC',

    [Parameter(Mandatory = $false)]
    [string]$StaticAddressCidr,

    [Parameter(Mandatory = $false)]
    [string]$Gateway,

    [Parameter(Mandatory = $false)]
    [string[]]$NameServers = @('1.1.1.1', '8.8.8.8')
)

$ErrorActionPreference = 'Stop'

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw $Message
    }
}

function New-NetworkSection {
    if ([string]::IsNullOrWhiteSpace($StaticAddressCidr)) {
@"
    network:
      version: 2
      ethernets:
        all-en:
          match:
            name: "en*"
          dhcp4: true
"@
    }
    else {
        if ([string]::IsNullOrWhiteSpace($Gateway)) {
            throw 'Gateway is required when StaticAddressCidr is provided.'
        }

        $nameServerList = ($NameServers | ForEach-Object { "            - $_" }) -join "`n"
@"
    network:
      version: 2
      ethernets:
        all-en:
          match:
            name: "en*"
          dhcp4: false
          addresses:
            - $StaticAddressCidr
          routes:
            - to: default
              via: $Gateway
          nameservers:
            addresses:
$nameServerList
"@
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$usbRoot = "${UsbDriveLetter}:\"
$noCloudPath = Join-Path $usbRoot 'nocloud'
$bundlePath = Join-Path $noCloudPath 'local-llm-src'

Assert-PathExists -Path $usbRoot -Message "USB drive ${UsbDriveLetter}: was not found."
Assert-PathExists -Path (Join-Path $usbRoot 'casper') -Message "${UsbDriveLetter}: does not look like an Ubuntu Server installer USB (missing casper folder)."

New-Item -ItemType Directory -Path $bundlePath -Force | Out-Null

$requiredFiles = @(
    'local-llm.env.example',
    'apply-ollama-gpu-policy.sh',
    'run-open-webui.sh',
    'validate-local-llm.sh',
    'local-llm-open-webui.service',
    'bootstrap-local-llm-host.sh',
    'local-llm-first-boot.service',
    'local-llm-first-boot-runner.sh',
    'local-llm-health-check.sh',
    'local-llm-health-check.service',
    'local-llm-health-check.timer',
    'skippy-preseed.cfg'
)

foreach ($file in $requiredFiles) {
    $sourcePath = Join-Path $PSScriptRoot $file
    Assert-PathExists -Path $sourcePath -Message "Missing source file: $sourcePath"
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $bundlePath $file) -Force
}

$networkSection = New-NetworkSection

$userData = @"
#cloud-config
autoinstall:
  version: 1
  locale: $Locale
  keyboard:
    layout: $KeyboardLayout
  timezone: $Timezone
  identity:
    hostname: $Hostname
    username: $AdminUsername
    password: "$LinuxPasswordHash"
  ssh:
    install-server: true
    allow-pw: true
$networkSection  packages:
    - openssh-server
    - curl
    - build-essential
  late-commands:
    - curtin in-target --target=/target -- mkdir -p /opt/local-llm-src /var/lib/local-llm
    - curtin in-target --target=/target -- cp -a /cdrom/nocloud/local-llm-src/. /opt/local-llm-src/
    - curtin in-target --target=/target -- chmod 755 /opt/local-llm-src/*.sh
    - curtin in-target --target=/target -- mkdir -p /usr/local/lib /etc/systemd/system
    - curtin in-target --target=/target -- cp /opt/local-llm-src/local-llm-first-boot-runner.sh /usr/local/lib/
    - curtin in-target --target=/target -- cp /opt/local-llm-src/local-llm-health-check.sh /usr/local/lib/
    - curtin in-target --target=/target -- chmod 755 /usr/local/lib/local-llm-*.sh
    - curtin in-target --target=/target -- cp /opt/local-llm-src/local-llm-first-boot.service /etc/systemd/system/
    - curtin in-target --target=/target -- cp /opt/local-llm-src/local-llm-health-check.service /etc/systemd/system/
    - curtin in-target --target=/target -- cp /opt/local-llm-src/local-llm-health-check.timer /etc/systemd/system/
    - curtin in-target --target=/target -- systemctl daemon-reload
    - curtin in-target --target=/target -- systemctl enable local-llm-first-boot.service
"@

$metaData = @"
instance-id: skippy-local-llm
local-hostname: $Hostname
"@

Set-Content -LiteralPath (Join-Path $noCloudPath 'user-data') -Value $userData -NoNewline -Encoding utf8
Set-Content -LiteralPath (Join-Path $noCloudPath 'meta-data') -Value $metaData -NoNewline -Encoding utf8

Write-Host "Prepared unattended install files on ${UsbDriveLetter}:\nocloud" -ForegroundColor Green
Write-Host ''
Write-Host 'Boot instructions:' -ForegroundColor Cyan
Write-Host '1. Boot the Z8 G4 from this USB drive.'
Write-Host '2. At the GRUB menu, edit the linux line and append:'
Write-Host '   autoinstall ds=nocloud\;s=/cdrom/nocloud/'
Write-Host '3. Continue boot; installer will run unattended with cloud-init.'
Write-Host ''
Write-Host 'Installation flow:' -ForegroundColor Cyan
Write-Host '- Ubuntu Server will install automatically'
Write-Host '- Cloud-init will copy Local_LLM files and enable first-boot service'
Write-Host '- On first reboot, local-llm-first-boot.service will run automatically'
Write-Host '- First-boot runner will execute bootstrap-local-llm-host.sh'
Write-Host '- Health monitoring will be enabled via systemd timer'
Write-Host ''
Write-Host 'After installation completes:' -ForegroundColor Cyan
Write-Host "ssh daniel@${Hostname}  (you will be prompted for password)"
Write-Host 'sudo journalctl -u local-llm-first-boot -f  # Monitor first-boot process'
Write-Host ''
Write-Host 'Note: Full bootstrap can take 10-20 minutes depending on model download.' -ForegroundColor Yellow
Write-Host 'Monitor via SSH for progress.'
