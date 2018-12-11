function Get-User{
    param(
        [parameter(ParameterSetName='String_Parameter')]
        [string] $Name='jeff',
        [int] $Age=25,
        [parameter(ParameterSetName='File_Parameter')]
        [object] $User
    )
        Write-Output $Name,$Age.ToString(),$User
    
}

function Get-Test{
    param(
        [string] $Args
    )
        Write-Output Args
    
}