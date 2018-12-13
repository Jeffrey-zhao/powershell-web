#get folder's list
function Invoke-Script {
    param(
        [parameter(Mandatory=$true)]
        [string] $ScriptPath
    )
    $results=Get-ChildItem -Path $ScriptPath |Find-Function

    return $results |ConvertTo-Json
}
#get script's functions
function Invoke-Function {
    param(
        [parameter(Mandatory=$true)]
        [string] $ScriptPath,

        [parameter(Mandatory=$true)]
        [string] $FunctionName
    )
    $parameters = Get-CommandParameter -ScriptPath $ScriptPath -FunctionName $FunctionName
    $detail = Get-Help $FunctionName -detailed
    $ret = @{parameters = $parameters; detail = $detail}
    return ConvertTo-Json $ret -Depth 5
}

function Execute-Function {
    param(
        [parameter(Mandatory=$true)]
        [string] $FunctionName,

        [parameter(Mandatory=$true)]
        $ArgumentList
    )
    Invoke-Expression "$FunctionName $ArgumentList" 
}

