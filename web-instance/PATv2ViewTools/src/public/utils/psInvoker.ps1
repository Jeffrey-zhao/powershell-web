#get folder's list
function Invoke-Script {
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath,

        [parameter(Mandatory = $true)]
        [string] $HelpFilePath
    )

    $functions = Get-ChildItem -Path $ScriptPath |Find-Function
    Get-Detail -ScriptPath $ScriptPath -FunctionNames $functions.Name -HelpFilePath $HelpFilePath
    return ConvertTo-Json -InputObject @($functions)
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
    $ret = [PSCustomObject]@{parameters = $parameters}
    
    return ConvertTo-Json $ret -Depth 5
}                                                               

#get script's help or function help
function Get-Detail {
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath,

        [parameter(Mandatory = $false)]
        [string[]] $FunctionNames,

        [parameter(Mandatory = $true)]
        [string] $HelpFilePath
    )
    $folder = (Get-Item -Path $ScriptPath).BaseName
    if (-not (Test-Path -Path "$HelpFilePath\$folder")) {
        $fileFolder=New-Item -Path "$HelpFilePath\$folder" -ItemType Directory
    }else{
        $fileFolder=Get-item -path "$HelpFilePath\$folder"
    }
    # script file
    Get-help -path $ScriptPath -Detailed |Out-File "$($fileFolder.FullName)\script.txt" -Encoding UTF8 -Force

    # function file
    foreach($item in $FunctionNames){
        Get-Help $item -detailed |Out-File "$($fileFolder.FullName)\$($item).txt" -Encoding UTF8 -Force
    }
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
