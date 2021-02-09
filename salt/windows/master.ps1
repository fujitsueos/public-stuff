param(
    [string]$vmname,
    [string]$salthostname,
    [string]$salturl,
    [string]$minionversion,
    [string]$installminion,
    [string]$username,
    [string]$password,
    [string]$minionid,
    [String]$appnames

)

if($installminion -eq $True) {
    .\bootstrap-salt.ps1 -minion $minionid -master $salthostname -version $minionversion

    .\saltclient.ps1 -saltmaster $salturl -username $username -password $password -minionid $minionid -appnames $appnames
 }
