# cache file localtion
$hypervHostsCache = ".\hyperv-vhosts-cache.json"

$bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$data = @{ boot_time = $bootTime }

$data | ConvertTo-Json | Set-Content -Path $hypervHostsCache
