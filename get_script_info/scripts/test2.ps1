function Write-Stuff([parameter(ParameterSetName="Stuff")][string] $arg="Stuff")
{
    Write-Output $arg
}

function Write-Test($arg1,$arg2)
{
    Write-Host $arg1,$args2
}