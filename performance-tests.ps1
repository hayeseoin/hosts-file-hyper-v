echo 'Get VM list'
Measure-Command { Get-VM | Where-Object { $_.State -eq "Running" } }

$name = "eight-four.local"
echo 'Get IPs'
Measure-Command { (Get-VMNetworkAdapter -VMName $name).IPAddresses | Where-Object { $_ -match '^[0-256].*\.*\.*' } }

echo 'Get Uptime'
Measure-Command { (Get-VMNetworkAdapter -VMName $name).Uptime | Where-Object { $_ -match '^[0-256].*\.*\.*' } }
