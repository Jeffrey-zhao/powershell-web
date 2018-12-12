function Get-User {
    param(
        [parameter(ParameterSetName = 'File')]
        [string] $Args='jeff'
    )
    Write-Output $Args
    
}

function Get-Test {
    param(
        [parameter(ParameterSetName = 'File')]
        [string] $Args='pp'
    )
    Write-Output $Args
    
}