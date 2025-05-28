$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1"  

# echo $ScriptConfig.runningVms
# return

if (-not $ScriptConfig.runningVms) {
    Write-Log 'No VMs. Shutting down.'
    return
}

# Assume system hasn't been restarted, and switches are listening to each other
$hasRestarted = $false
$switches_forwarding = $true 

# Initialize cache if it doesn't exist
$cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json
if (-not $cachedVMFile.LastBootTime) {
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
    $switches_forwarding = $false
}

if ($cachedVMFile.virtual_machines.IPs | Where-Object {-not $_}) {
    $hasRestarted = $true
}

# In case an empty IP gets loaded in
if ($cachedVMFile.virtual_machines | Where-Object {$_.IPs -eq ""}) {
    Write-Log "No IP assigned to some VMs. Rebuilding cache."
    $hasRestarted = $true
}

$vmsDetected = Detect-New-VMs

if ((-not $vmsDetected) -and ( -not $hasRestarted)) {
    Write-Log 'No new VMs have been detected. Exiting.'
    return
} else {
    Write-Log 'New VMs have been detected, or the system has restarted'
    $refreshNeeded = $true
}

# Have switches forward to each other
if ($config.hasRestarted -or (-not $switches_forwarding)) {
    Write-Log 'Switches might not be loaded. Re-running command.'
    Get-NetIPInterface | Where-Object {
    $_.InterfaceAlias -eq $configg.wslSwitch`
        -or    $_.InterfaceAlias -eq $configg.wslSwitch `
    } | Set-NetIPInterface -Forwarding Enabled -Verbose
    $switches_forwarding = $true
}

# Update VM cache and hosts file
Write-Log "Updating VM cache."
. "$PSScriptRoot\get-vms.ps1"

Write-Log "Hosts file needs to be updated."
. "$PSScriptRoot\update_hosts.ps1"