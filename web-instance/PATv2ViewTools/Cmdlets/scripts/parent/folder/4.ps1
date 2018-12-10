function Get-User{
    param(
        [string] $Name,
        [int] $Age
    )
        Write-Output $Name,$Age.ToString()
    
}

function Get-Test{
    param(
        [string] $Args
    )
        Write-Output Args
    
}