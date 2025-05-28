$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json

$ScriptConfig = @{
    runningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }
}

function Detect-New-VMs() {

    $vmUptimes = `
        Get-CimInstance `
        -Namespace "root\virtualization\v2" `
        -ClassName "Msvm_ComputerSystem" | 
        Where-Object {
            ($_.EnabledState -eq 2) -and ($_.OnTimeInMilliseconds -gt $0)
        } | Select-Object ElementName, OnTimeInMilliseconds

    $thresholdMs =  $config.new_vm_threshold
    
    $recentVMs = $vmUptimes | Where-Object {
        $_.OnTimeInMilliseconds -lt $thresholdMs
    }

    if ($recentVMs.Count -eq 0) {
        # Write-Output 'No full refresh needed.'
        return $false
    }

    # echo 'Full refresh needed'
    return $true
}

function Create-HyperV-Hosts-Cache() {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime.ToUniversalTime()
    $refreshNeeded = $true
    $data = @{ 
        LastBootTime = $bootTime 
        RefreshNeeded = $refreshNeeded 
        virtual_machines = @()
        switches_forwarding = @()
        hosts_file_updated = $false
    }
    $data | ConvertTo-Json | Set-Content -Path $config.hypervHostsCache
}

function Write-Log {
    param (
        [string]$Message
    )

    if (-not (Test-Path $config.logsDir)) {
        New-Item -ItemType Directory -Path $config.logsDir | Out-Null
    }

    $date = Get-Date -Format "yyyy-MM-dd"
    $logFile = Join-Path $config.logsDir "$date.log"

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp`t$Message"

    Add-Content -Path $logFile -Value $entry
}
