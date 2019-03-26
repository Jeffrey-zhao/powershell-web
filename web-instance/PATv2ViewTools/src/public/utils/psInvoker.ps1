<#
    .Description
        this script will invoke util functions to implement some scenarios
#>


function Invoke-Script {
    <#
    .Description
        get folder's function list
    #>
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath,

        [parameter(Mandatory = $false)]
        [string] $HelpFilePath
    )

    try{
        $functions = Get-ChildItem -Path $ScriptPath |Find-Function
        if(![string]::IsNullOrEmpty($HelpFilePath))
        {
            Get-Detail -ScriptPath $ScriptPath -FunctionNames $functions.Name -HelpFilePath $HelpFilePath
        }
        return ConvertTo-Json -InputObject @($functions)
    }catch{}
}


function Invoke-Function {
    <#
    .Description
        get script's functions's parameters
    #>
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath,

        [parameter(Mandatory = $true)]
        [string] $FunctionName
    )
    $parameters = Get-CommandParameter -ScriptPath $ScriptPath -FunctionName $FunctionName
    $ret = [PSCustomObject]@{parameters = $parameters}
    
    return ConvertTo-Json $ret -Depth 7
}                                                               


function Get-Detail {
    <#
    .Description
        get script's help or function help
    #>
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
        $fileFolder=Get-item -Path "$HelpFilePath\$folder"
    }
    <# script file #>
    Get-Help -Name $ScriptPath -Detailed |Out-File "$($fileFolder.FullName)\script.txt" -Encoding UTF8 -Force

    <# function file #>
    foreach($item in $FunctionNames){
        Get-Help -Name $item -detailed |Out-File "$($fileFolder.FullName)\$($item).txt" -Encoding UTF8 -Force
    }
}  


function Execute-Function {
    <#
    .Description
        execute an escaped string-command
    #>
    param(
        [parameter(Mandatory = $true)]
        [string] $FunctionName,

        [parameter(Mandatory = $true)]
        [string] $ArgumentList
    )

    $express = ""
    if(![string]::IsNullOrEmpty($ArgumentList) -and $ArgumentList -ne 'undefined'){
        $ArgumentString = [system.uri]::UnescapeDataString($ArgumentList)
        add-type -assembly system.web.extensions
    
        $ps_js = new-object system.web.script.serialization.javascriptSerializer
        $ArgumentObj = $ps_js.DeserializeObject($ArgumentString)
        
        foreach ($item in $ArgumentObj) {
            $express += "$(Format-Parameter -Key $item.name -Value $item.value -Type $item.type)"
        }
        if ([string]::IsNullOrEmpty($express)) {
            $express = " Write-Output 'No executing any functions...' "
        }
        else {
            $express = " $FunctionName " + $express
        }
    }else{
        $express= " $FunctionName "
    }
    Write-Host $express
    Invoke-Expression -Command $express
}


function Format-Parameter {
    <#
    .Description
        handle function parameter type from C# type to powershell type
    #>
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
                [DateTime] $date=new-object DateTime
                $temp = [DateTime]::TryParse($value.trim("'"), [ref] $date);
                $retValue=$value
                break
            }
            "System.String[]" {
                $retValue=($value -split ',') -join ','
                $temp=$true
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