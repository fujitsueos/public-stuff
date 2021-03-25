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
  $saltRepo = "https://archive.repo.saltproject.io/windows/"
  $year = $minionversion.Substring(0, 4)
  If (($minionversion.ToLower() -eq 'latest') -or [int]$year -gt 2019) {
      $saltRepo = "https://repo.saltproject.io/windows/"
  }
  
  .\bootstrap-salt.ps1 -repourl $saltRepo -minion $minionid -master $salthostname -version $minionversion
  .\saltclient.ps1 -saltmaster $salturl -UserName $username -password $password -minionid $minionid
}
