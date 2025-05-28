# echo 'These are some performance checks..'

$timeTaken = Measure-Command { .\3get-vms.ps1 }
# echo 'in milliseconds'
echo $timeTaken.TotalMilliseconds