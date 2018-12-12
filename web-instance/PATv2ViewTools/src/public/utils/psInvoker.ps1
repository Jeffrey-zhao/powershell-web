#get folder's list
function Invoke-Script {
    param(
        [string] $ScriptPath
    )
    $results=Get-ChildItem -Path $ScriptPath |Find-Function

    return $results |ConvertTo-Json
}
#get script's functions
function Invoke-Function {
    param(
        [string] $ScriptPath,
        [string] $FunctionName
    )
    $parameters = Get-CommandParameter -ScriptPath $ScriptPath -FunctionName $FunctionName
    $detail = Get-Help $FunctionName -detailed
    $ret = [PSCustomObject]@{parameters = $parameters; detail = $detail}
    
    return ConvertTo-Json $ret -Depth 5
}

function Execute-Function {
    param(
        [string] $FunctionName,
        $ArgumentList
    )
    Invoke-Expression "$FunctionName $ArgumentList" 
}

