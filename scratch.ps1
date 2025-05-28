$vmUptimes = Get-CimInstance -Namespace "root\virtualization\v2" -ClassName "Msvm_ComputerSystem" | 
    Where-Object { $_.EnabledState -eq 2 -and $_.ElementName -like '*.local'} | 
    Select-Object ElementName, OnTimeInMilliseconds

$thresholdMs = 2 * 60 * 1000  # 2 minutes in ms

# $needsFullRefresh = $vmUptimes | Where-Object { $_.OnTimeInMilliseconds -lt $thresholdMs -and $_.ElementName }

$recentVMs = $vmUptimes | Where-Object {
    $_.OnTimeInMilliseconds -lt $thresholdMs
}

if ($recentVMs.Count -eq 0) {
    Write-Output 'No full refresh needed.'
    return $false
}

echo 'Full refresh needed'
return $true

