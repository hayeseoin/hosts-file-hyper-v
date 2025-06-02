$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1"  

if (-not $ScriptConfig.runningVms) {
    Write-Log 'No VMs. Shutting down.'
    return
}

# Check if the --no-wsl flag is provided
$noWsl = $false
if ($args -contains "--no-wsl") {
    $noWsl = $true
    Write-Log "Flag --no-wsl detected. Skipping WSL switch checks."
}

if (-not $noWsl) {
    Write-Log 'Checking if Default and WSL switches are forwarding to each other.'
    $switches_forwarding = Check-Switches-Forwarding
    if (-not $switches_forwarding) {
        Write-Log "Default and WSL switches are not forwarding to each other."
        Set-Switches-Forwarding
    } else {
        Write-Log "Switches are already forwarding to each other."
    }
}

# Create the cache if it doesn't exist
if (-not (Test-Path $config.hypervHostsCache)) {
    Write-Log "Cache file doesn't exist - creating it."
    New-Item -Path $config.hypervHostsCache -ItemType File -Force | Out-Null
}

$cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json
if (-not $cachedVMFile.LastBootTime) {
    Write-Log "Initialize cache if it already isn't."
    Create-HyperV-Hosts-Cache
}

# Has system been rebooted? 
$lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime.ToUniversalTime()

$systemBootTimeDifference = (
    $cachedVMFile.LastBootTime - $lastBootTime
    ).Duration()

if ($systemBootTimeDifference -gt [TimeSpan]::FromSeconds(10)) {
    Create-HyperV-Hosts-Cache
}

# Update VM cache and hosts file
Write-Log "Updating VM cache."
. "$PSScriptRoot\get-vms.ps1"

Write-Log "Hosts file needs to be updated."
. "$PSScriptRoot\update_hosts.ps1"

