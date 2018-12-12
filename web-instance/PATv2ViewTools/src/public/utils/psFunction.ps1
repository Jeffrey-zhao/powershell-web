filter Find-Function {
    $path = $_.FullName
    $lastwrite = $_.LastWriteTime.ToString('MM/dd/yyyy HH:mm:ss')
    $text = Get-Content -Path $path
    
    if ($text.Length -gt 0) {
       
        $token = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref] $token, [ref] $errors)
        $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
            Select-Object -Property Name, Path, LastWriteTime |
            ForEach-Object {
            $_.Path = $path
            $_.LastWriteTime = $lastwrite
            $_
        }
    }
}

function Get-CommandParameter {
    param(
        [parameter(Mandatory = $true)]
        [string] $ScriptPath,
        [string] $FunctionName
    )

    $scripts = get-childItem $ScriptPath -Recurse -Filter *.ps1 
    $scripts | ForEach-Object { Import-Module $_.FullName -Force }
    $functions = $scripts | Find-Function 
    
    if(![string]::IsNullOrEmpty($FunctionName)){
        $functions =$functions |Where-Object {$_.Name -ieq $FunctionName}
    }

    $functionsInfo = $functions |ForEach-Object { Get-Command -Name $_.Name} |
         Select-Object -Property Name, ScriptBlock, Parameters, ParameterSets
    $commonParameter=@('Verbose','Debug','ErrorAction','WarningAction','InformationAction',
                        'ErrorVariable','WarningVariable','InformationVariable','OutVariable',
                        'OutBuffer','PipelineVariable')
    $paramters = $functionsInfo |ForEach-Object {$temp = $_
        $paramBlock = $_.ScriptBlock.Ast.Body.ParamBlock.Parameters
        $parameter=$_.ScriptBlock.Ast.Parameters
        $parameterSetNames=@()
        $parameters=@()
        $blockParameters=@()
        foreach($item in $temp.ParameterSets)
        {
            $name=$item.Name
            $paramsInSetName=$item.Parameters |Where-Object {$_.Name -notin $commonParameter}
            $argCollection=@()
            foreach($item_arg in $paramsInSetName)
            {
                $argCollection+=@{Arg=$item_arg.Name;IsMandatory=$item_arg.IsMandatory}
            }
            $parameterSetNames+=@{Name=$name;ParameterNames=$argCollection}
        }
     
        $parameters+=$parameter| ForEach-Object {@{Name=$_.ParameterSetName
            StaticType=$_.StaticType
            DefaultValue=$_.DefaultValue
            ParameterSetNames=$_.ParameterSets}} 

         $blockParameters+=$paramBlock|Select-Object @{l='Name';e={$_.Name.VariablePath.ToString()}},
            @{l='StaticType';e={$_.StaticType.FullName}}, 
            @{l='DefaultValue';e={$_.DefaultValue.ToString()}} 
        @{Name = $_.Name
            BlockParameters = $blockParameters
            Parameters=$parameters      
            ParameterSetName=$parameterSetNames
            }
        }
    return $paramters 
}