$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json

$switches = @()
$switches_forwarding = $true

$ifs = (Get-NetIPInterface | Where-Object {
            $_.InterfaceAlias -eq $config.wslSwitch`
             -or $_.InterfaceAlias -eq $config.defaultSwitch
        }
    )

foreach ($if in $ifs) {
    $forwarding = $if.Forwarding
    $switches += $forwarding
} 

if (-not $switches | Where-Object {$_}) {
    $switches_forwarding = $false
}



# $cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json
# $cachedVMFile.switches_forwarding = $switches_forwarding
# echo $cachedVMFile.switches_forwarding
# $cachedVMFile | ConvertTo-Json -Depth 3 | Set-Content $config.hypervHostsCache
