# echo 'These are some performance checks..'

$timeTaken = Measure-Command { .\entrypoint.ps1 }
# echo 'in milliseconds'
echo $timeTaken.TotalMilliseconds