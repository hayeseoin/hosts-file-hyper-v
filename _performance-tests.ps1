# Check performance by running this manually
$timeTaken = Measure-Command { .\entrypoint.ps1 }
echo $timeTaken.TotalMilliseconds