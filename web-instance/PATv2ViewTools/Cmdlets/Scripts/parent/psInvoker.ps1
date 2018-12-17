#get folder's list
function Invoke-Script {
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath
    )
    $results = @(Get-ChildItem -Path $ScriptPath |Find-Function)

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

    $ArgumentString = [system.uri]::UnescapeDataString($ArgumentList)
    add-type -assembly system.web.extensions

    $ps_js = new-object system.web.script.serialization.javascriptSerializer
    $ArgumentObj = $ps_js.DeserializeObject($ArgumentString)
    $express = ""

    foreach ($item in $ArgumentObj) {
        $express += "$(Format-Parameter -Key $item.name -Value $item.value -Type $item.type)"
    }
    if ([string]::IsNullOrEmpty($express)) {
        $express = " Write-Output 'No executing any functions...' "
    }
    else {
        $express = " $FunctionName " + $express
    }
    Invoke-Expression -Command $express
}

function Format-Parameter {
    param(
        [string] $key,
        [string] $value,
        [string] $type
    )
    $retValue = $null
    $retParam = ""
    $temp = $true
    $seq = " "
    if ([string]::IsNullOrEmpty($key) -or [string]::IsNullOrEmpty($value)) {
        return $retParam
    }
    else {
        switch ($type) {
            "System.Int32" {
                $temp = [Int32]::TryParse($value, [ref] $retValue);
                break
            }
            "System.Single" {
                $temp = [Single]::TryParse($value, [ref] $retValue);
                break
            }
            "System.Double" {
                $temp = [Double]::TryParse($value, [ref] $retValue);
                break
            }
            "System.Boolean" {
                $temp = [Boolean]::TryParse($value, [ref] $retValue); 
                $retValue = "$" + $retValue; 
                break
            }
            "System.Switch" {
                $temp = [Boolean]::TryParse($value, [ref] $retValue); 
                $seq = ":";
                $retValue = "$" + $retValue;
                break
            }
            "System.DateTime" {
                $temp = [DateTime]::TryParse($value, [ref] $retValue);
                break
            }
            "System.Object" {
                $temp = [Double]::TryParse($value, [ref] $retValue);
                break
            }
            default {
                $retValue = $value; 
                $temp = $true;
                break
            }
        }

        if ($temp) {
            $retParam = "-$key$seq$retValue "
        }
        else {
            Write-Host "something wrong when parse parameter ($key) you given "
        }
    }
    return $retParam
}
