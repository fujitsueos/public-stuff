param(
  [string]$installminion,
  [string]$salthostname,
  [string]$salturl,
  [string]$minionversion,
  [string]$username,
  [string]$password,
  [string]$minionid

)
$saltRepo = "https://archive.repo.saltproject.io/windows"
if ($installminion -eq $True) {
  .\bootstrap-salt.ps1 -repourl $saltRepo -minion $minionid -master $salthostname -version $minionversion

  .\saltclient.ps1 -saltmaster $salturl -UserName $username -password $password -minionid $minionid
}
