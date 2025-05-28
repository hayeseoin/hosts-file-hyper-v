$wslIf="vEthernet (WSL (Hyper-V firewall))"
$defaultIf="vEthernet (Default Switch)"

$ifs = (Get-NetIPInterface | Where-Object {
            $_.InterfaceAlias -eq $wslIf -or $_.InterfaceAlias -eq $defaultIf
        }
    )

foreach ($if in $ifs) {

    $name = $if.InterfaceAlias
    $forwarding = $if.Forwarding

    echo $name
    echo $forwarding
} 