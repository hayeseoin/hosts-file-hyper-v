echo 'These are some performance checks..'

$timeTaken = Measure-Command { .\get-interfaces.ps1 }
echo 'in milliseconds'
echo $timeTaken.TotalMilliseconds