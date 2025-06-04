$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1" 

$cachedVMFile = Get-Content $config.hypervHostsCache | ConvertFrom-Json
$hostsFile = Get-Content $config.hosts_file_path
$updatedHostsFile = $hostsFile.Clone()

if ($config.debug_flag) {
    Write-Log "DEBUG --- Hosts File Clone START ---"
    Write-Log "$updatedHostsFile"
    Write-Log "DEBUG --- Hosts File Clone END ---"
}


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

    if ($config.debug_flag) {
    Write-Log "DEBUG --- Host entry for $name START ---"
    Write-Log "$hostEntry"
    Write-Log "DEBUG --- Host entry for $name END ---"
        }

    if (-not ($name -like "*.local")) {
        $hostEntry += " $name.local"
        Write-Log "Adding $name.local as well."
    }
    if ($index) {
        $lineIndex = ($index - 1)
            if ($config.debug_flag) {
                Write-Log "DEBUG --- Line indexes for $name START ---"
                Write-Log "Index: $index"
                Write-Log "Line Index: $lineIndex"
                Write-Log "DEBUG --- Line indexes for $name END ---"
            }
        Write-Log "Replacing host entry for $name"
        $updatedHostsFile[$lineIndex] = $hostEntry
    } else {
        Write-Log "Adding host entry for $name"
        $updatedHostsFile += $hostEntry
    }

    if ($config.debug_flag) {
    Write-Log "DEBUG --- Hosts at end of loop for $name START ---"
    Write-Log "$updatedHostsFile"
    Write-Log "DEBUG --- Hosts at end of loop for $name $name END ---"
    }
}


$updatedHostsFileLength = $updatedHostsFile.Count
Write-Log "Updating hosts file."
Write-Log "Lenth of updated hosts file is $updatedHostsFileLength"

if ($updatedHostsFile.Count -lt 1) {
    Write-Log "WARNING: Hosts file appears to be empty or malformed. Aborting to avoid overwrite."
    exit 1
}

# $updatedHostsFile | Set-Content -Path $config.hosts_file_path -Encoding ASCII

# Generate timestamped temp path
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempHostsPath = "$($config.hosts_file_path)-hvhm-$timestamp"

# Write to the temp file
$updatedHostsFile | Set-Content -Path $tempHostsPath -Encoding ASCII -Force
Write-Log "Wrote updated hosts file to temp path: $tempHostsPath"

# Create a backup of the existing hosts file
$backupPath = "$($config.hosts_file_path).hvhm_bak_$timestamp"
try {
    Copy-Item -Path $config.hosts_file_path -Destination $backupPath -Force
    Write-Log "Backed up original hosts file to: $backupPath"
} catch {
    Write-Log "ERROR: Failed to back up hosts file: $($_.Exception.Message)"
    throw
}

# Replace old hosts file with new one 
try {
    Remove-Item -Path $config.hosts_file_path -Force
    Write-Log "Deleted original hosts file."
} catch {
    Write-Log "ERROR: Failed to delete original hosts file: $($_.Exception.Message)"
    throw
}

try {
    Move-Item -Path $tempHostsPath -Destination $config.hosts_file_path -Force
    Write-Log "Replaced hosts file with updated version: $tempHostsPath"
} catch {
    Write-Log "ERROR: Failed to move temp hosts file into place: $($_.Exception.Message)"
    throw
}