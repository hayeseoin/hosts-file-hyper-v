$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1"  

$vmData = @()
$cachedVMFile = [PSCustomObject]@{}
$cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json

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


    $maxRetries = 12
    $retryDelay = 5
    $attempt = 0

    do {
        $ips = (Get-VMNetworkAdapter -VMName $name).IPAddresses | Where-Object {
            $_ -match '^\d{1,3}(\.\d{1,3}){3}$'
        }

        if ($ips.Count -eq 0) {
            Write-Log "No IP assigned to VM '$name' yet. Attempt $($attempt + 1) of $maxRetries. Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
            $attempt++
        }
    } while ($ips.Count -eq 0 -and $attempt -lt $maxRetries)

    if ($attempt -eq $maxRetries) {
        Write-Log "Could not fetch IP for '$name'."
    }

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

Write-Log 'Updating cache file.'
$cachedVMFile.virtual_machines = $newVMList
$cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $config.hypervHostsCache
