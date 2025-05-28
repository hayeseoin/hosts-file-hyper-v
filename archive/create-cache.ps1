# cache file localtion
$hypervHostsCache = ".\hyperv-vhosts-cache.json"

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
    $data | ConvertTo-Json | Set-Content -Path $hypervHostsCache
}


# Create-HyperV-Hosts-Cache