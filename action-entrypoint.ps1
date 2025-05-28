$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1"  

Write-Log 'Switches might not be loaded. Re-running command.'
Get-NetIPInterface | Where-Object {
$_.InterfaceAlias -eq $configg.wslSwitch`
    -or    $_.InterfaceAlias -eq $configg.wslSwitch `
} | Set-NetIPInterface -Forwarding Enabled -Verbose

# Update VM cache and hosts file
Write-Log "Updating VM cache."
. "$PSScriptRoot\action-get-vms.ps1"

Write-Log "Hosts file needs to be updated."
. "$PSScriptRoot\update_hosts.ps1"