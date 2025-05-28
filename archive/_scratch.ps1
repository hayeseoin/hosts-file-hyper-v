$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json

$cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json

if ($cachedVMFile.virtual_machines | Where-Object {$_.IPs -eq ""}) {
    $hasRestarted = $true
}

# echo $cachedVMFile.virtual_machines.IPs | Where-Object -ne $null