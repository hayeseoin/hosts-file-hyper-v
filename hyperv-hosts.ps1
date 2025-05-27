$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$startTag = "# __hyper__v__vm__hosts__ START"
$endTag = "# __hyper__v__vm__hosts__ END"

$vmList = Get-VM | Where-Object { $_.State -eq "Running" }

foreach ($vm in $vmList) {
    $name = $vm.Name
    $ip = (Get-VMNetworkAdapter -VMName $name).IPAddresses | Where-Object { $_ -match '^[0-256].*\.*\.*'  }

    $vmEntries += "$ip`t$name`n"
    }

$block = @()
$block += $startTag + "`n"
$block += "# This section is auto-generated. Do not edit.`n"
$block += $vmEntries
$block += $endTag

$current = Get-Content $hostsPath -Raw
if ($current.Contains($block)) {
    echo 'Block is there - exiting...'
    return
}

$original = Get-Content $hostsPath -ErrorAction Stop

$startIndex = ($original | Select-String -SimpleMatch $startTag).LineNumber
$endIndex   = ($original | Select-String -SimpleMatch $endTag).LineNumber

$blockExists = 1
if ($startIndex -eq $null) {
    $blockExists = 0
}

$blockStartsFile = 1
if ($startIndex -ne 1) {
    $blockStartsFile = 0
} 

if ($blockExists -and $blockStartsFile) {
    # Block is already at the top — replace it
    $after = $original[$endIndex..($original.Count - 1)]
    $newHosts = $block + $after
}
elseif ($blockExists -and -not $blockStartsFile) {
    # Block is not at the top — remove it and re-add at the top
    $before = $original[0..($startIndex - 2)]
    $after  = $original[$endIndex..($original.Count - 1)]
    $strippedOriginal = $before + $after
    $newHosts = $block + "" + $strippedOriginal  # extra "" adds a newline
}
else {
    # No block found — prepend it to the file
    $newHosts = $block + "" + $original
}

# If the block is the last line in the file, $after evaluates to the end-tag
if ($after.Count -eq 1 -and $after[0].Trim() -eq "# __hyper__v__vm__hosts__ end") {
    $after = @()
}

$newHostsFile = "$hostsPath.hyperv-automate"
$newHosts | Set-Content $newHostsFile
$diff = Compare-Object (Get-Content $hostsPath) (Get-Content $newHostsFile)
if ($diff) {
    echo 'Files differ'
} else {
    echo 'No changes needed'
    Remove-Item $newHostsFile
    return
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$backupPath = "$hostsPath-hypervbackup-$timestamp"
$original | Set-Content $backupPath -Encoding ASCII
Move-Item -Path $newHostsFile -Destination $hostsPath -Force
echo "Hosts file updated with current VM entries."
