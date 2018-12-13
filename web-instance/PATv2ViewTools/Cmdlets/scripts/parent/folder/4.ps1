function Get-User {
    param(
        [parameter()]
        [string] $User='jeff',

        [parameter(ParameterSetName = 'Test')]
        [string] $PP
    )
    Write-Output "$User,$PP"
}

function Get-Test {
    param(
        [parameter(Mandatory=$true)]
        [string] $Args='pp',
        [parameter()]
        [string] $Test
    )
    Write-Output $Args
    
}