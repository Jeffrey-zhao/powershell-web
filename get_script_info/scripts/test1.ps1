function Write-Args
{
    [cmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ParameterSetName='arg1')]
        [string] $arg1='Hello',

        [Parameter(Mandatory=$false,ParameterSetName='arg2')]
        [string] $arg2="Jeffrey",

        [Parameter(Mandatory=$false,ParameterSetName='arg1')]
        [string] $arg3
    )
    Write-Output $arg1,$arg2,$arg3
}