[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedSha256,

    [string]$ApkSignerPath = "apksigner"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ApplicationPath {
    param([Parameter(Mandatory = $true)][string]$PathOrCommand)

    if (Test-Path -LiteralPath $PathOrCommand) {
        $item = Get-Item -LiteralPath $PathOrCommand
        if ($item.PSIsContainer) {
            throw "ApkSignerPath must point to an executable file."
        }

        return $item.FullName
    }

    $command = Get-Command -Name $PathOrCommand -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
    return $command.Source
}

$apk = Get-Item -LiteralPath $ApkPath -ErrorAction Stop
if ($apk.PSIsContainer -or $apk.Extension -ne ".apk") {
    throw "ApkPath must point to an existing .apk file."
}

$expectedFingerprint = ($ExpectedSha256.Trim() -replace "[:\s]", "").ToUpperInvariant()
if ($expectedFingerprint -notmatch "^[0-9A-F]{64}$") {
    throw "ExpectedSha256 must be a 64-character SHA-256 certificate fingerprint."
}

$apkSigner = Resolve-ApplicationPath -PathOrCommand $ApkSignerPath
$verificationOutput = & $apkSigner verify --verbose --print-certs --Werr $apk.FullName 2>&1
$verificationExitCode = $LASTEXITCODE

if ($verificationExitCode -ne 0) {
    throw "apksigner rejected the APK. Review the private release log for details."
}

$fingerprintPattern =
    "(?im)^\s*Signer\s+#\d+\s+certificate\s+SHA-256\s+digest:\s*([0-9A-F: ]+)\s*$"
$actualFingerprints = @(
    [regex]::Matches(
        ($verificationOutput -join [Environment]::NewLine),
        $fingerprintPattern
    ) |
        ForEach-Object {
            ($_.Groups[1].Value -replace "[:\s]", "").ToUpperInvariant()
        } |
        Where-Object { $_ -match "^[0-9A-F]{64}$" } |
        Sort-Object -Unique
)

if ($actualFingerprints.Count -ne 1) {
    throw "Expected exactly one valid signer certificate fingerprint in the APK."
}

if ($actualFingerprints[0] -ne $expectedFingerprint) {
    throw "APK signer certificate does not match the expected production fingerprint."
}

Write-Output "PASS: APK signature is valid and the signer fingerprint matches."
