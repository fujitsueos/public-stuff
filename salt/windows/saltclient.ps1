param(
  [string]$saltmaster,
  [string]$username,
  [string]$password,
  [string]$minionid
)




Add-Type @"
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



function Retry-Command {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory = $true)]
    [scriptblock]$ScriptBlock,

    [Parameter(Position = 1,Mandatory = $false)]
    [int]$Maximum = 5,

    [Parameter(Position = 2,Mandatory = $false)]
    [int]$Delay = 5,

    [Parameter(Position = 3,Mandatory = $false)]
    [string]$ErrorMessage = 'Execution failed.'
  )

  begin {
    $cnt = 0
  }

  process {
    do {
      $cnt++
      try {
        $ScriptBlock.Invoke()
        return
      } catch {
        Write-Output $_.Exception.InnerException.Message -ErrorAction Continue
        Start-Sleep -Seconds $Delay
      }
    } while ($cnt -lt $Maximum)

    throw $ErrorMessage
  }
}


class SaltClient{
  [string]$endpoint
  [string]$username
  [string]$password
  [string]$token = ""

  SaltClient ([string]$e,[string]$u,[string]$p) {
    $this.endpoint = $e
    $this.username = $u
    $this.password = $p

  }

  [string] getToken () {
    if ([string]::IsNullOrEmpty($this.token) -eq $True) {
      $url = $this.endpoint + "/login"
      $payload = @{
        username = $this.username
        password = $this.password
        eauth = "pam"
      }

      $response = Retry-Command -ErrorMessage "Token request failed" -ScriptBlock {
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        return Invoke-RestMethod -Method Post -Uri $url -Body $payload
      }

      $this.token = $response.return.token
    }
    return $this.token
  }

  [bool] minionExists ([string]$minionId) {
    $url = $this.endpoint + "/keys"

    $response = Retry-Command -ErrorMessage "Minion exists request failed" -ScriptBlock {
      [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
      return Invoke-RestMethod -Method Get -Uri $url -Headers @{ 'X-Auth-Token' = $this.getToken() }
    }

    return $minionId -in $response.return.minions_pre
  }

  [bool] autosignMinion ([string]$minionId) {
    $minionArg = "touch /etc/salt/pki/master/minions_autosign/" + $minionId
    $payload = @{
      client = "local"
      tgt = "saltmaster"
      fun = "cmd.run"
      arg = $minionArg
    }

    $response = Retry-Command -ErrorMessage "Autosign Minion request failed" -ScriptBlock {
      [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
      return Invoke-RestMethod -Method Post -Uri $this.endpoint -Headers @{ 'X-Auth-Token' = $this.getToken() } -Body $payload
    }

    return $True
  }

  [bool] waitAndAutosignMinion ([string]$minionId) {
    [int]$tries = 0
    while ($tries -lt 10) {
      $exist = $this.minionExists($minionId)
      if ($exist) {
        return $this.autosignMinion($minionId)
      }
      Start-Sleep -Seconds 10
      $tries++
    }
    return $False
  }

  [bool] refreshWindowsrepository ([string]$minionId) {
    $minionArg = "salt-run winrepo.update_git_repos; salt $($minionId) pkg.refresh_db"
    $payload = @{
      client = "local"
      tgt = "saltmaster"
      fun = "cmd.run"
      arg = $minionArg
    }

    $response = Retry-Command -ErrorMessage "Refresh Windows repository request failed" -ScriptBlock {
      [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
      return Invoke-RestMethod -Method Post -Uri $this.endpoint -Headers @{ 'X-Auth-Token' = $this.getToken() } -Body $payload
    }
    return $True
  }

}

[SaltClient]$client = [SaltClient]::new($saltmaster,$username,$password)

$client.waitAndAutosignMinion($minionid)
