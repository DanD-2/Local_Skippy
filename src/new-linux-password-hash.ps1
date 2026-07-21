[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [SecureString]$Password,

    [Parameter(Mandatory = $false)]
    [switch]$Prompt,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

function Get-PlainTextFromSecureString {
    param([Parameter(Mandatory = $true)][SecureString]$SecureValue)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-PasswordPlainText {
    if ($Password) {
        return Get-PlainTextFromSecureString -SecureValue $Password
    }

    if ($Prompt -or -not $Password) {
        $first = Read-Host -Prompt 'Enter password for Linux user' -AsSecureString
        $second = Read-Host -Prompt 'Confirm password' -AsSecureString

        $firstPlain = Get-PlainTextFromSecureString -SecureValue $first
        $secondPlain = Get-PlainTextFromSecureString -SecureValue $second

        if ($firstPlain -ne $secondPlain) {
            throw 'Passwords did not match.'
        }

        if ([string]::IsNullOrWhiteSpace($firstPlain)) {
            throw 'Password cannot be empty.'
        }

        return $firstPlain
    }

    throw 'No password input was provided.'
}

function Get-HashWithOpenSsl {
    param([Parameter(Mandatory = $true)][string]$PasswordText)

    $openssl = Get-Command openssl -ErrorAction SilentlyContinue
    if (-not $openssl) {
        return $null
    }

    $result = $PasswordText + "`n" | & openssl passwd -6 -stdin 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($result)) {
        return $null
    }

    return ($result | Select-Object -First 1).Trim()
}

function Get-HashWithWsl {
    param([Parameter(Mandatory = $true)][string]$PasswordText)

    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wsl) {
        return $null
    }

    $result = $PasswordText + "`n" | & wsl -e sh -lc "openssl passwd -6 -stdin" 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($result)) {
        return $null
    }

    return ($result | Select-Object -First 1).Trim()
}

function Get-HashWithDocker {
    param([Parameter(Mandatory = $true)][string]$PasswordText)

    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        return $null
    }

    $script = "apk add --no-cache openssl >/dev/null 2>&1; openssl passwd -6 -stdin"
    $result = $PasswordText + "`n" | & docker run --rm -i alpine:3.22 sh -lc $script 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($result)) {
        return $null
    }

    return ($result | Select-Object -First 1).Trim()
}

$passwordText = Get-PasswordPlainText

$hash = Get-HashWithOpenSsl -PasswordText $passwordText
if (-not $hash) {
    $hash = Get-HashWithWsl -PasswordText $passwordText
}
if (-not $hash) {
    $hash = Get-HashWithDocker -PasswordText $passwordText
}

if (-not $hash) {
    throw 'Could not generate SHA-512 crypt hash. Install openssl on Windows, or enable WSL/docker.'
}

if (-not $Quiet) {
    Write-Host 'Generated Linux SHA-512 crypt password hash.' -ForegroundColor Green
}

Write-Output $hash
