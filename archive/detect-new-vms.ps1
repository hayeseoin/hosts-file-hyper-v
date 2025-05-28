function Detect-New-VMs() {

    $vmUptimes = `
        Get-CimInstance `
        -Namespace "root\virtualization\v2" `
        -ClassName "Msvm_ComputerSystem" | 
        Where-Object {
            ($_.EnabledState -eq 2) -and ($_.OnTimeInMilliseconds -gt $0)
        } | Select-Object ElementName, OnTimeInMilliseconds

    $thresholdMs =  90 * 1000  # 1.5 minutes
    
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