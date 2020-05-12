param(
    [string]$version,
    $AllowRemoteExecution = $True
)
# install AV
$path = 'C:\av'
$fileName = 'output.txt'
$fullFilePath = (Join-Path -Path $path -ChildPath $fileName)
New-Item -ItemType Directory -Path $path
New-Item -ItemType File -Path $fullFilePath
$version | Set-Content $fullFilePath

# init data disks
Get-Disk | Where-Object {$_.PartitionStyle -eq 'RAW'} | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume

if($AllowRemoteExecution) {
  Enable-PSRemoting
}
