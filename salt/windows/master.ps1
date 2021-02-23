param(
  [string]$installminion,
  [string]$salthostname,
  [string]$salturl,
  [string]$minionversion,
  [string]$username,
  [string]$password,
  [string]$minionid

)

if ($installminion -eq $True) {
  .\bootstrap-salt.ps1 -minion $minionid -master $salthostname -Version $minionversion

  .\saltclient.ps1 -saltmaster $salturl -UserName $username -password $password -minionid $minionid
}
