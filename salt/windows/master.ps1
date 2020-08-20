param(
    [string]$vmname,
    [string]$saltmaster,
    [string]$minionversion,
    [string]$installminion,
    [string]$username,
    [string]$password,
    [string]$minionid,
    [String]$appnames

)

if($installminion -eq $True) {
    .\bootstrap-salt.ps1 -minion $minionid -master $saltmaster -version $minionversion

    .\saltclient.ps1 -saltmaster $saltmaster -username $username -password $password -minionid $minionid -appnames $appnames
 }
