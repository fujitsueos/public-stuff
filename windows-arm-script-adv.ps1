<#
.SYNOPSIS
    Advanced ARM Powershell script for Windows.

.DESCRIPTION
    Main script to run post provision tasks for Windows.

.PARAMETER AntiVirusAgentVersion
    String value for AV agent version, this doesn't actually install anything.

.PARAMETER ZabbixConfig
    JSON encoded string for zabbix configuration. {Username = <zabbixUsername>; Password = <zabbixPassword>; Host = <zabbixHost>}
    Requires an actual Zabbix server for host registration! Agent is downloaded from www.zabbix.com

.PARAMETER AllowRemoteExecution
    If truthie, execute Enable-PSRemoting

.PARAMETER InitDisk
    If truthie, init and format data disks (Initialize-Disk, New-Partition, Format-Volume)

.EXAMPLE
    ./windows-arm-script-adv.ps1 -AntiVirusAgentVersion "1.0" -ZabbixConfig '{"Username": "Admin", "Password": "Zabbix", "Host": "10.0.0.2"}' -AllowRemoteExecution $true
#>

param(
  $AntiVirusAgentVersion,
  $ZabbixConfig,
  $AllowRemoteExecution,
  $InitDisk = $true
)

# set errors to silent
$ErrorActionPreference = "SilentlyContinue"

function Invoke-InstallZabbixAgent {
  [CmdletBinding()]
  param (
    [Parameter(mandatory)]
    [PSCredential]$Credentials,
    [Parameter(mandatory)]
    [string]$ZabbixHost
  )

  Install-Module -Name PS-Zabbix-Host -Force -Confirm:$False

  # download agent msi package from www.zabbix.com and install it
  Install-ZabbixAgent

  # IP address of the client where the agent is running
  $ip = Get-LocalIPAddress

  # Zabbix server token
  $token = New-ZabbixToken -ZabbixHost $ZabbixHost -Credentials $credentials

  # create new host by using the REST API and token
  New-ZabbixHost -ZabbixHost $ZabbixHost -Token $token -AgentIPAddress $ip
}

function Install-AntivirusAgent {
  [CmdletBinding()]
  param (
    [Parameter(mandatory)]
    [string]$Version
  )
  $path = 'C:\av'
  $fileName = 'output.txt'
  $fullFilePath = (Join-Path -Path $path -ChildPath $fileName)
  New-Item -ItemType Directory -Path $path
  New-Item -ItemType File -Path $fullFilePath
  $version | Set-Content $fullFilePath
}

function Invoke-InitDisks {
  Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume
}

if ($InitDisk) {
  Invoke-InitDisks
}

if ($AllowRemoteExecution) {
  Enable-PSRemoting
}

if ($ZabbixConfig) {
  $ZabbixConfig = $ZabbixConfig | ConvertFrom-Json

  $zabbixCredentials = New-Object System.Management.Automation.PSCredential(
    $ZabbixConfig.Username,
    (ConvertTo-SecureString $ZabbixConfig.Password -AsPlainText -Force)
  )

  Invoke-InstallZabbixAgent -Credentials $zabbixCredentials -ZabbixHost $ZabbixConfig.Host

}

if ($AntiVirusAgentVersion) {
  Install-AntivirusAgent -Version $AntiVirusAgentVersion
}
