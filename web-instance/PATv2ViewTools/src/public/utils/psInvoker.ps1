function Invoke-Script {
    param(
        [string] $ScriptPath
    )
    $results=Get-ChildItem -Path $ScriptPath |Find-Function

    return $results |ConvertTo-Json
}

function Invoke-Function {
    param(
        [string] $ScriptPath,
        [string] $FunctionName
    )
    $parameters = Get-CommandParameter -ScriptPath $ScriptPath -FunctionName $FunctionName
    $detail = Get-Help $FunctionName -detailed
    $ret = [PSCustomObject]@{Parameters = $parameters; Detail = $detail}
    
    return ConvertTo-Json $ret -Depth 3
}

