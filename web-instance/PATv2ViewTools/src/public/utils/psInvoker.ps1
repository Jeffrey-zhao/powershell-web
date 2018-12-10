

function Invoke-Script {
    param(
        [string] $ScriptPath
    )
    Import-Module ./psFunction.ps1 -Force
    Get-ChildItem -Path $ScriptPath |Find-Function
}

function Invoke-Function {
    param(
        [string] $ScriptPath
    )
    Import-Module ./psFunction.ps1 -Force
    Get-CommandParameter -ScriptPath $ScriptPath
}

