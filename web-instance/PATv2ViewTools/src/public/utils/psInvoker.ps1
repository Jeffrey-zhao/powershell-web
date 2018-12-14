#get folder's list
function Invoke-Script {
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath
    )
    $results = Get-ChildItem -Path $ScriptPath |Find-Function

    return $results |ConvertTo-Json
}
#get script's functions
function Invoke-Function {
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath,

        [parameter(Mandatory = $true)]
        [string] $FunctionName
    )
    $parameters = Get-CommandParameter -ScriptPath $ScriptPath -FunctionName $FunctionName
    $detail = Get-Help $FunctionName -detailed
    $ret = [PSCustomObject]@{parameters = $parameters; detail = $detail}
    
    return ConvertTo-Json $ret -Depth 5
}

function Execute-Function {
    param(
        [parameter(Mandatory = $true)]
        [string] $FunctionName,

        [parameter(Mandatory = $true)]
        [string] $ArgumentList
    )
    $ArgumentList
    $ArgumentString = [system.uri]::UnescapeDataString($ArgumentList)
    add-type -assembly system.web.extensions

    $ps_js = new-object system.web.script.serialization.javascriptSerializer
    $ArgumentObj = $ps_js.DeserializeObject($ArgumentString)
    $express = ''

    foreach ($item in $ArgumentObj) {
        $express += Format-Parameter -Key $ArgumentObj.name -Value $ArgumentObj.value -Type $ArgumentObj.type
    }
    if ([string]::IsNullOrEmpty($express)) {
        $express = " Write-Output 'No executing any functions...' "
    }
    else {
        $express = " $FunctionName " + $express
    }
    Write-Output $express
    Invoke-Expression -Command $express
}

function Format-Parameter {
    param(
        [string] $key,
        [string] $value,
        [string] $type
    )
    $retValue = $null
    $retParam = ''
    if ([string]::IsNullOrEmpty($key) -or [string]::IsNullOrEmpty($value)) {
        return ''
    }
    else {
        switch ($type) {
            'System.Int32' { [Double]::TryParse($value, [ref] $retValue); break}
            'System.Float' {[Double]::TryParse($value, [ref] $retValue); break}
            'System.Double' {[Double]::TryParse($value, [ref] $retValue); break}
            'System.Boolean' {[Double]::TryParse($value, [ref] $retValue); break}
            'System.DateTime' {[Double]::TryParse($value, [ref] $retValue); break}
            'System.Object' {[Double]::TryParse($value, [ref] $retValue); break}
            'System.String[]' {[Double]::TryParse($value, [ref] $retValue); break}
            default { $retValue = $value; break}
        }
        if ([string]::IsNullOrEmpty($retValue)) {
            $retParam = ""
        }
        else {
            $retParam = "-$($key) $retValue "
        }
    }
    return $retParam
}
