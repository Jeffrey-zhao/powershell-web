function Get-Test2 {
    param(
        [parameter(Mandatory = $true)]
        [string] $from,
        [parameter()]
        [string] $Test = 'test'
    )
    $context
    Write-Output $from,$test 
}