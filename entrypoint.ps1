$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1"  

if (-not $ScriptConfig.runningVms) {
    Write-Log 'No VMs. Shutting down.'
    return
}

# Check if Default and WSL switches are forwading to each other
Write-Log 'Checking if Default and WSL switches are forwading to each other.'
$switches_forwarding = Check-Switches-Forwarding
if (-not $switches_forwarding) {
    Write-Log "Default and WSL switches are not forwading to each other."
    Set-Switches-Forwarding
} else {Write-Log "Switches are already forwarding to each other."}

# Assume system hasn't been restarted, and switches are listening to each other
$hasRestarted = $false

# Initialize cache if it doesn't exist
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
    $hasRestarted = $true
}

if ($cachedVMFile.virtual_machines.IPs | Where-Object {-not $_}) {
    $hasRestarted = $true
}

# In case an empty IP gets loaded in
if ($cachedVMFile.virtual_machines | Where-Object {$_.IPs -eq ""}) {
    Write-Log "No IP assigned to some VMs. Rebuilding cache."
    $hasRestarted = $true
}


# # Check for new VMs - not needed if not run on a schedule
# $vmsDetected = Detect-New-VMs

# if ((-not $vmsDetected) -and ( -not $hasRestarted)) {
#     Write-Log 'No new VMs have been detected. Exiting.'
#     return
# } else {
#     Write-Log 'New VMs have been detected, or the system has restarted'
#     $refreshNeeded = $true
# }

# Update VM cache and hosts file
Write-Log "Updating VM cache."
. "$PSScriptRoot\get-vms.ps1"

Write-Log "Hosts file needs to be updated."
. "$PSScriptRoot\update_hosts.ps1"

