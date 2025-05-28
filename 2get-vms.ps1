function Round-ToNearestMinute ($dt) {
    if ($dt.Second -ge 60) {
        return [DateTime]($dt.AddSeconds(60 - $dt.Second).AddMilliseconds(-$dt.Millisecond))
    } else {
        return [DateTime]($dt.AddSeconds(-$dt.Second).AddMilliseconds(-$dt.Millisecond))
    }
}

function State-Cache-Equal () {

    $currentVMNames = ($runningVMs.Name | Sort-Object) -join ','
    $cachedVMNames = ($cachedVMFile.virtual_machines.Name | Sort-Object) -join ','

    if ($currentVMNames -ne $cachedVMNames) {
        return $false
    }
    $minimalNewList = $runningVMs | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            BootTime = (Round-ToNearestMinute (($currentDate).Add(-$_.Uptime).ToUniversalTime())).ToString("s")
        }
    }

    $cachedMinimalList = $cachedVMFile.virtual_machines | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            BootTime = (Round-ToNearestMinute ([DateTime]$_.BootTime)).ToString("s")
        }
    }

    $stateSort = $minimalNewList | Sort-Object Name
    $cacheSort = $cachedMinimalList | Sort-Object Name

    $diff = @()
    $diff += Compare-Object $stateSort $cacheSort -Property Name
    $diff += Compare-Object $stateSort $cacheSort -Property BootTime


    if (-not $diff) {
        return $true
    } else {
         return $false 
        }
}

$runningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }

$currentDate = Get-Date

$vmData = @()
$hypervHostsCache = ".\hyperv-vhosts-cache.json"
$cachedVMFile = @{}

# If no running VMs, exit fast
if (-not $runningVms) {
    $cachedVMFile.virtual_machines = @()
    $cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $hypervHostsCache
    echo 'No VMs active. Emtying cache.'
    return
}

$lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

if (Test-Path $hypervHostsCache) {
    try {
        $cachedVMFile = Get-Content $hypervHostsCache | ConvertFrom-Json

        # Convert to PSCustomObject if it's a plain array or null
        if ($cachedVMFile -isnot [psobject] -or $cachedVMFile.PSObject.TypeNames[0] -eq 'System.Object[]') {
            $cachedVMFile = [PSCustomObject]@{}
        }
    } catch {
        Write-Warning "Could not parse existing cache. Starting fresh."
        $cachedVMFile = [PSCustomObject]@{}
    }
}

if (-not $cachedVMFile.PSObject.Properties['virtual_machines']) {
    $cachedVMFile | Add-Member -MemberType NoteProperty -Name "virtual_machines" -Value @()
}

if (-not $cachedVMFile.PSObject.Properties['virtual_machines']) {
    $cachedVMFile.virtual_machines = @()
}

if (State-Cache-Equal) {
    echo 'State and cache are the same'
    return
}

$newVMList = @()

foreach ($vm in $runningVMs) {
    $name = $vm.Name
    $uptime = $vm.Uptime
    $vmBootTime = (Get-Date).Add(-$uptime).ToUniversalTime()

    $ips = @()

    $cachedVM = $cachedVMFile.virtual_machines | Where-Object { $_.Name -eq $name }

    if ($cachedVM) {
        echo "VM $name is cached? True"

        $vmCached = $true
        $hasRestarted = $false
        $cachedvmBootTime = [datetime]$cachedVM.BootTime
        $ips = $cachedVM.IPs

        $vmBootTimeDiff = ($vmBootTime - $cachedvmBootTime).Duration()
        echo "Time diff is $vmBootTimeDiff"

        if ($vmBootTimeDiff -gt [TimeSpan]::FromSeconds(5)) {
            echo 'Time diff block hit'
            $hasRestarted = $true
        } 
        
        if ($lastBootTime -lt $cachedVMFile.boot_time) {
            $hasRestarted = $true
        } 

    } else {
        echo "VM $name is cached? False"
        $hasRestarted = $false
    }

    echo "$name or system has been restarted since last cache? $hasRestarted"

    if ($hasRestarted -or (-not $cachedVM)) {
        echo "IP for $name is being reset? True"
        $ips = (Get-VMNetworkAdapter -VMName $name).IPAddresses | Where-Object {
            $_ -match '^\d{1,3}(\.\d{1,3}){3}$' 
        }    
    } else { echo "IP for $name is being reset? False" }

    echo "Boot time of VM is:  $vmBootTime"
    echo "Cached boot time is $cachedvmBootTime"

    $newVMList += [PSCustomObject]@{
        Name   = $name
        # Uptime = $uptime
        BootTime = $vmBootTime
        IPs    = $ips -join ', '
        HasRestarted = $hasRestarted

    }
    echo ''
}

if (-not $cachedVMFile.virtual_machines) {
    echo 'Updating cache file.'
    $cachedVMFile.virtual_machines = $newVMList
    $cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $hypervHostsCache
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

echo "diff is: $diff_log"
echo "Has anything been restarted? $anyRestarted_log" 

if ((-not $diff) -and ($anyRestarted.Count -eq 0)) {
    echo 'Noting to update'
    return
}

echo 'Updating cache file.'
$cachedVMFile.virtual_machines = $newVMList
$cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $hypervHostsCache
