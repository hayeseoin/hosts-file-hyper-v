$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1" 

$cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json
$hostsFile = Get-Content $config.hosts_file_path
$updatedHostsFile = $hostsFile.Clone()

# if ($hostsFile.Count -lt 2) {
#     Write-Log "WARNING: Hosts file appears to be empty or malformed. Aborting to avoid overwrite."
#     exit 1
# }

foreach ($hypervHost in $cachedVMFile.virtual_machines) {
    $name = $hypervHost.Name
    $ips = $hypervHost.IPs
    $pattern = "\b$name(\.local)?\b"
    $index = ($hostsFile | Select-String -Pattern "$pattern").LineNumber

    Write-Log "$name detected on Hyper V."
    if ($index) {
        Write-Log "Detected on line $index"
    } else {
        Write-Log "Not in existing hosts file."
    }

    # Match Power Toys Hosts File GUI editor
    $hostEntry = "  " + $ips.PadRight(15) + $name

    if (-not ($hypervHost -like "*.local")) {
        $hostEntry += " $name.local"
        Write-Log "Adding $name.local as well."
    }
    if ($index) {
        $lineIndex = ($index - 1)
        Write-Log "Replacing host entry for $name"
        $updatedHostsFile[$lineIndex] = $hostEntry
    } else {
        Write-Log "Adding host entry for $name"
        $updatedHostsFile += $hostEntry
    }
}

# echo $updatedHostsFile
Write-Log "Updating hosts file."

if ($updatedHostsFile.Count -lt 2) {
    Write-Log "WARNING: Hosts file appears to be empty or malformed. Aborting to avoid overwrite."
    exit 1
}

$updatedHostsFile | Set-Content -Path $config.hosts_file_path -Encoding ASCII