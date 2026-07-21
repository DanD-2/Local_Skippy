[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[A-Za-z]$')]
    [string]$UsbDriveLetter = 'D',

    [Parameter(Mandatory = $false)]
    [string]$Hostname = 'Skippy',

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = 'daniel',

    [Parameter(Mandatory = $false)]
    [string]$StaticAddressCidr = '192.168.128.5/21',

    [Parameter(Mandatory = $false)]
    [string]$Gateway = '192.168.128.1',

    [Parameter(Mandatory = $false)]
    [string[]]$NameServers = @('192.168.128.254', '192.168.128.253', '1.1.1.1'),

    [Parameter(Mandatory = $false)]
    [PSCredential]$AdminCredential,

    [Parameter(Mandatory = $false)]
    [switch]$Dhcp,

    [Parameter(Mandatory = $false)]
    [switch]$SkipConfirmation
)

$ErrorActionPreference = 'Stop'

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw $Message
    }
}

function Write-Checklist {
    param(
        [Parameter(Mandatory = $true)][string]$Drive,
        [Parameter(Mandatory = $true)][bool]$UsingDhcp,
        [Parameter(Mandatory = $true)][string]$Ip,
        [Parameter(Mandatory = $true)][string]$Route,
        [Parameter(Mandatory = $true)][string[]]$Dns
    )

    Write-Host ''
    Write-Host 'Skippy USB install preflight checklist' -ForegroundColor Cyan
    Write-Host "1. USB drive detected: ${Drive}:"
    Write-Host '2. Ubuntu installer media structure detected (casper folder exists).'
    Write-Host "3. Identity defaults: hostname=$Hostname username=$AdminUsername"
    if ($UsingDhcp) {
        Write-Host '4. Network mode: DHCP'
    }
    else {
        Write-Host "4. Network mode: static ($Ip, gateway $Route, DNS $($Dns -join ', '))"
    }
    Write-Host '5. Local_LLM automation payload will be copied to /cdrom/nocloud/local-llm-src.'
    Write-Host ''
}

$scriptRoot = Split-Path -Parent $PSCommandPath
$prepareScript = Join-Path $scriptRoot 'prepare-ubuntu-server-26.04-usb-autoinstall.ps1'
$hashScript = Join-Path $scriptRoot 'new-linux-password-hash.ps1'
$usbRoot = "${UsbDriveLetter}:\"

Assert-PathExists -Path $prepareScript -Message "Missing script: $prepareScript"
Assert-PathExists -Path $hashScript -Message "Missing script: $hashScript"
Assert-PathExists -Path $usbRoot -Message "USB drive ${UsbDriveLetter}: was not found."
Assert-PathExists -Path (Join-Path $usbRoot 'casper') -Message "${UsbDriveLetter}: does not look like an Ubuntu Server installer USB (missing casper folder)."

$requiredPayload = @(
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

foreach ($file in $requiredPayload) {
    Assert-PathExists -Path (Join-Path $scriptRoot $file) -Message "Missing required payload file: $file"
}

Write-Checklist -Drive $UsbDriveLetter -UsingDhcp $Dhcp.IsPresent -Ip $StaticAddressCidr -Route $Gateway -Dns $NameServers

if (-not $SkipConfirmation) {
    $response = Read-Host 'Continue and write autoinstall files to USB? (y/N)'
    if ($response -notin @('y', 'Y', 'yes', 'YES')) {
        throw 'Cancelled by user.'
    }
}

if ($AdminCredential) {
    $LinuxHash = & pwsh -NoProfile -File $hashScript -Password $AdminCredential.Password -Quiet
}
else {
    $LinuxHash = & pwsh -NoProfile -File $hashScript -Prompt -Quiet
}

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($LinuxHash)) {
    throw 'Failed to generate admin password hash.'
}

$prepareArgs = @(
    '-NoProfile'
    '-File', $prepareScript
    '-UsbDriveLetter', $UsbDriveLetter
    '-Hostname', $Hostname
    '-AdminUsername', $AdminUsername
    '-LinuxPasswordHash', $LinuxHash
)

if (-not $Dhcp) {
    $prepareArgs += '-StaticAddressCidr', $StaticAddressCidr
    $prepareArgs += '-Gateway', $Gateway
    $prepareArgs += '-NameServers', ($NameServers -join ',')
}

& pwsh @prepareArgs
if ($LASTEXITCODE -ne 0) {
    throw 'USB preparation failed.'
}

Write-Host ''
Write-Host 'One-command automation completed.' -ForegroundColor Green
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '1. Boot Z8 G4 from USB and add:'
Write-Host '   autoinstall ds=nocloud\;s=/cdrom/nocloud/'
Write-Host '2. After first SSH login, run:'
Write-Host '   sudo /opt/local-llm-src/bootstrap-local-llm-host.sh'
