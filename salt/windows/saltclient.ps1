param(
    [string]$saltmaster,
    [string]$username,
    [string]$password,
    [string]$minionid,
    [String]$appnames
)

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@


class SaltClient {
    [string]$endpoint
    [string]$username
    [string]$password
    [string]$token = ""

    SaltClient([string]$e, [string]$u, [string]$p){
        $this.endpoint = "https://$e"
        $this.username = $u
        $this.password = $p
    }

    [string] getToken(){
        if([string]::IsNullOrEmpty($this.token) -eq $True){
            $url = $this.endpoint + "/login"
            $payload = @{
                username = $this.username
                password = $this.password
                eauth = "pam"
            }

            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            $response = Invoke-RestMethod -Method Post -Uri $url -Body $payload
            $this.token = $response.return.token
        }
        return $this.token
    }

    [bool] minionExists([string]$minionId){
        $url = $this.endpoint + "/keys"

        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        $response = Invoke-RestMethod -Method Get -Uri $url -Headers @{'X-Auth-Token'=$this.getToken()}
        foreach ($minion in $response.return.minions_pre) {
            if($minion -eq $minionId){
                return $True
            }
        }
        return $False
    }

    [bool] autosignMinion([string]$minionId){
        $minionArg = "touch /etc/salt/pki/master/minions_autosign/" + $minionId
        $payload = @{
            client= "local"
            tgt= "saltmaster"
            fun= "cmd.run"
            arg= $minionArg
        }

        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        $response = Invoke-RestMethod -Method Post -Uri  $this.endpoint -Headers @{'X-Auth-Token'=$this.getToken()} -Body $payload
        return $True
    }

    [bool] waitAndAutosignMinion([string]$minionId){
        [int]$tries = 0
        while($tries -lt 10) {
            $exist = $this.minionExists($minionId)
            if($exist) {
                return $this.autosignMinion($minionId)
            }
            Start-Sleep -Seconds 10
            $tries++
        }
        return $False
    }

    [bool] refreshWindowsrepository([string]$minionId){
        $minionArg = "salt-run winrepo.update_git_repos; salt $($minionId) pkg.refresh_db"
        $payload = @{
            client= "local"
            tgt= "saltmaster"
            fun= "cmd.run"
            arg= $minionArg
        }

        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        $response = Invoke-RestMethod -Method Post -Uri  $this.endpoint -Headers @{'X-Auth-Token'=$this.getToken()} -Body $payload
        return $True
    }

    [string] installApp([string]$minionId, [string]$appName){
        $url = $this.endpoint + "/minions" 
        $payload = @{
            client= "local"
            tgt= $minionId
            fun= "pkg.install"
            arg= $appName
        }

        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        $response = Invoke-RestMethod -Method Post -Uri  $url -Headers @{'X-Auth-Token'=$this.getToken()} -Body $payload
        return $response.return.jid
    }

    [bool] waitForJob([string]$appJid){
        $url = $this.endpoint + "/jobs/$($appJid)"
        [int]$tries = 0

        while($tries -lt 20) {
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            $response = Invoke-RestMethod -Method Get -Uri  $url -Headers @{'X-Auth-Token'=$this.getToken()}
            if(![string]::IsNullOrEmpty($response.info.Result) -eq $True){
                return $True
            }
            Start-Sleep -Seconds 10
            $tries++
        }

        return $False
    }

    [bool] waitAndInstallApp([string]$minionId, [string]$appName){
        $jobId = $this.installApp($minionId, $appName)
        $this.waitForJob($jobId)
        return $True
    }

}

[SaltClient]$client = [SaltClient]::new($saltmaster, $username, $password)

$client.waitAndAutosignMinion($minionid)
$client.refreshWindowsrepository($minionid)

foreach ($appName in $appnames.Split(",")) {

    if(![string]::IsNullOrEmpty($appName) -eq $True){

        Start-Sleep -Seconds 20
        $client.waitAndInstallApp($minionid, $appName)
    }
}
