$vmData = @()
$hypervHostsCache = ".\hyperv-vhosts-cache.json"
$existingData = @{}

if (Test-Path $hypervHostsCache) {
    try {
        $existingData = Get-Content $hypervHostsCache | ConvertFrom-Json

        # Convert to PSCustomObject if it's a plain array or null
        if ($existingData -isnot [psobject] -or $existingData.PSObject.TypeNames[0] -eq 'System.Object[]') {
            $existingData = [PSCustomObject]@{}
        }
    } catch {
        Write-Warning "Could not parse existing cache. Starting fresh."
        $existingData = [PSCustomObject]@{}
    }
}

# Ensure the 'virtual_machines' property exists and is a list
if (-not $existingData.PSObject.Properties['virtual_machines']) {
    $existingData | Add-Member -MemberType NoteProperty -Name "virtual_machines" -Value @()
}

# Ensure existingData is a hashtable with 'virtual_machines' list
if (-not $existingData.PSObject.Properties['virtual_machines']) {
    $existingData.virtual_machines = @()
}

# Flag for demo — later replace with your real condition
$likelyNewIP = $true 

# Get updated VM data
$runningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }

foreach ($vm in $runningVMs) {
    $name = $vm.Name
    $uptime = $vm.Uptime.TotalMilliseconds
    $ips = @()

    # Check if this VM already exists in the virtual_machines array
    $existingVM = $existingData.virtual_machines | Where-Object { $_.Name -eq $name }

    if ($existingVM) {
        $existingUptime = $existingVM.Uptime.TotalMilliseconds
        $existingIP = $existingVM.IPs

        if ($uptime -lt $existingUptime) {
            $hasRestarted = $true
            $likelyNewIP = $true
        } else {
            $hasRestarted = $false
            # return
            }

        if ($likelyNewIP) {
            $ips = (Get-VMNetworkAdapter -VMName $name).IPAddresses | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }
        }
        if (-not $likelyNewIP -and $existingData.ContainsKey($name)) {
            $ips = $existingIP
        }
    }

    if ($existingVM) {
        # Update existing VM entry
        $existingVM.Uptime = $uptime
        if ($ips) { $existingVM.IPs = $ips -join ', ' }
    } else {
        # Add new VM entry
        $existingData.virtual_machines += [PSCustomObject]@{
            Name   = $name
            Uptime = $uptime
            IPs    = $ips -join ', '
        }
    }
}

# Write the updated data back
$existingData | ConvertTo-Json -Depth 3 | Set-Content $hypervHostsCache
