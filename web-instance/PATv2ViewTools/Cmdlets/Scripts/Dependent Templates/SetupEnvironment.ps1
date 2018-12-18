[cmdletbinding()]

Param
(
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateSet("int", "prod", "onebox")]
    [string]$Environment,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$WorkingDir
)

Write-host 'my testing';