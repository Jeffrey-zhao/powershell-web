[cmdletbinding()]

Param
(
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateSet("int", "prod", "onebox")]
    [string]$Environment,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$WorkingDir
)

if(![string]::IsNullOrEmpty($WorkingDir) -and ((Get-Item $WorkingDir) -is [System.IO.DirectoryInfo]))
{
    Set-Location $WorkingDir
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

ipmo .\Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.UI.dll

$authConfigNode=([xml](Get-Content ".\Scripts\PatScriptConfig.xml")).SelectNodes("root/authenticationContext/environment[@name='$($Environment.ToLower())']")
$authParameters=@{
            ClientId=$authConfigNode.SelectNodes("add[@name='ClientId']").value;
            RedirectUri=$authConfigNode.SelectNodes("add[@name='RedirectUri']").value;
            StsEndpointUri=$authConfigNode.SelectNodes("add[@name='StsEndpointUri']").value;
            WebApiRelyingPartyIdentifier=$authConfigNode.SelectNodes("add[@name='WebApiRelyingPartyIdentifier']").value;
            WebApiEndpointUri=$authConfigNode.SelectNodes("add[@name='WebApiEndpointUri']").value
            }

$global:context = Get-AdfsAuthenticationContext @authParameters