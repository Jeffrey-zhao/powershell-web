function Get-Test1 {
    param(
        [parameter(Mandatory = $true)]
        [string] $Args,
        [parameter()]
        [string] $Test = 'test'
    )
    Write-Output $Args  
}