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
    $ret = [PSCustomObject]@{parameters = $parameters; detail = $detail}
    
    return ConvertTo-Json $ret -Depth 5
}

function Execute-Function {
    param(
        [parameter(Mandatory=$true)]
        [string] $FunctionName,

        [parameter(Mandatory=$true)]
        [string] $ArgumentList
    )

    $ArgumentString=[system.uri]::UnescapeDataString($test)
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    $ArgumentObj=$ps_js.DeserializeObject($ArgumentString)
    $express=''
    foreach($kvp in $ArgumentObj.GetEnumerator())
    {
        $express+="-$($kvp.Keys[0]) $($kvp.Values[0]) "
    }
    if([string]::IsNullOrEmpty($express))
    {
        $express=" Write-Output 'No executing any functions...' "
    }else
    {
        $express=" $FunctionName "+$express
    }
    Write-Output $express
    #Invoke-Expression -Command $express
}
