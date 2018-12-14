function Get-User {
    param(
        [parameter()]
        [string] $User = 'jeff',

        [parameter(ParameterSetName = 'Test')]
        [string] $PP
    )
    Write-Output "$User,$PP"
}

function Get-Test {
    param(
        [parameter(Mandatory = $true)]
        [string] $Args,
        [parameter()]
        [string] $Test = 'test'
    )
    Write-Output $Args  
}