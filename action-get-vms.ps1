$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1"  
$vmData = @()
$cachedVMFile = [PSCustomObject]@{}
Create-HyperV-Hosts-Cache

$newVMList = @()
# Need to re-init cache to add VMs to it
if ($null -eq $cachedVMFile -or $cachedVMFile -isnot [psobject]) {
    $cachedVMFile = [PSCustomObject]@{}
    $cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json
}
$cachedVMFile.virtual_machines= @()

foreach ($vm in $ScriptConfig.runningVMs) {
    $name = $vm.Name
    $uptime = $vm.Uptime
    $vmBootTime = (Get-Date).Add(-$uptime).ToUniversalTime()

    $ips = @()

    $cachedVM = $cachedVMFile.virtual_machines | Where-Object { $_.Name -eq $name }

    if ($cachedVM) {
        Write-Log "VM $name is cached? True"

        $vmCached = $true
        $hasRestarted = $false
        $cachedvmBootTime = [datetime]$cachedVM.BootTime
        $ips = $cachedVM.IPs

        $vmBootTimeDiff = ($vmBootTime - $cachedvmBootTime).Duration()
        Write-Log "Time diff is $vmBootTimeDiff"

        if ($vmBootTimeDiff -gt [TimeSpan]::FromSeconds(5)) {
            Write-Log 'Time diff block hit'
            $hasRestarted = $true
        } 
        
        if ($lastBootTime -lt $cachedVMFile.boot_time) {
            $hasRestarted = $true
        } 

    } else {
        Write-Log "VM $name is cached? False"
        $hasRestarted = $false
    }

    Write-Log "$name or system has been restarted since last cache? $hasRestarted"

    if ($hasRestarted -or (-not $cachedVM)) {
        Write-Log "IP for $name is being reset? True"
        $ips = (Get-VMNetworkAdapter -VMName $name).IPAddresses | Where-Object {
            $_ -match '^\d{1,3}(\.\d{1,3}){3}$' 
        }    
    } else { Write-Log "IP for $name is being reset? False" }

    Write-Log "Boot time of VM is:  $vmBootTime"
    Write-Log "Cached boot time is $cachedvmBootTime"

    $newVMList += [PSCustomObject]@{
        Name   = $name
        BootTime = $vmBootTime
        IPs    = $ips -join ', '

    }
    Write-Log '---'
}

if (-not $cachedVMFile.virtual_machines) {
    Write-Log 'Updating cache file.'
    $cachedVMFile.virtual_machines = $newVMList
    $cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $config.hypervHostsCache
    return
}

$oldSorted = $cachedVMFile.virtual_machines | Sort-Object Name
$newSorted = $newVMList | Sort-Object Name
$diff =  Compare-Object $oldSorted $newSorted -Property Name, IPs
$anyRestarted = $newSorted | Where-Object { $_.HasRestarted -eq $true }

if (-not $diff) {
    $diff_log = 'No'
} else { $diff_log = $diff}
if (-not $anyRestarted) {
    $anyRestarted_log = 'No'
} else {$anyRestarted_log = $anyRestarted}

Write-Log "diff is: $diff_log"
Write-Log "Has anything been restarted? $anyRestarted_log" 

if ($refreshNeeded) {
    $cachedVMFile.RefreshNeeded = $false
    $cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $config.hypervHostsCache
}

if ((-not $diff) -and ($anyRestarted.Count -eq 0)) {
    Write-Log 'Noting to update'
    return
}

Write-Log 'Updating cache file.'
$cachedVMFile.hosts_file_updated = $false
$cachedVMFile.virtual_machines = $newVMList
$cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $config.hypervHostsCache
