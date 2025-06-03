$config = Get-Content "$PSScriptRoot\\config.json" | ConvertFrom-Json
. "$PSScriptRoot\utils.ps1"

$hostsFile = Get-Content "C:\\Windows\\System32\\drivers\\etc\\hosts.empty"

# Check if 'localhost' is in the content
if (-not ($hostsFile -match 'localhost')) {
    Write-Host "The word 'localhost' was not found in the target file. Exiting script."
    exit 1
}

echo $hostsFile.Count