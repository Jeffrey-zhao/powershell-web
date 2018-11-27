function Write-Args {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'arg')]
        [string] $arg="jeffrey"
    )
    
    if (![string]::IsNullOrEmpty($arg)) {
        Write-Output "arg :$arg"
        $arg>".\data\arg.txt"
    }
}