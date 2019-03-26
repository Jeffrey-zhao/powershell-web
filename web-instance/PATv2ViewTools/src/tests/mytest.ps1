function Get-Test {
    <#
        .DESCRIPTiON
            my testing
    #>
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [parameter(Mandatory = $false,Position=2,ParameterSetName='My')]
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [alias('FilePath')]
        [string] $Path='/zhza\tt.txt',

        [parameter(Mandatory = $false)]
        [parameter(Mandatory = $false,ParameterSetName='Others')]
        [string[]] $Names=@('pp','tt'),

        [parameter(Mandatory = $false,ParameterSetName='Yours')]
        [parameter(Mandatory = $false,ParameterSetName='Others')]
        [validateSet('a','b','c')]
        [string] $ParamEnum,

        [parameter(Mandatory = $false,Position=1,ParameterSetName='My')]
        [string] $script=@(1,2),

        [parameter(Mandatory = $false,Position=0,ParameterSetName='My')]
        [string] $Time=[datetime]::utcNow.toString('yyyy/MM/dd HH:mm:ss')

    )

    Write-Output 'tesing'
    <#
    ipmo .\mytest.ps1 -force
    $fn=(get-item -path function:get-Test)
    $parameters=$fn.ScriptBlock.Ast.Body.ParamBlock.Parameters
    $paramAttrs=$parameters |
        ForEach-Object {
        $name=$_.name;
        if($null -ne $_.DefaultValue)
        {
           $defaultValue=@{Static=$_.DefaultValue.Static;Value="'"+((invoke-expression $_.DefaultValue.ToString()) -join "','")+"'"}
        }else
        {
           $defaultValue=$null
        }
        @{
            Name=$name;
            DefaultValue=$defaultValue;
            Attributes=@($_.Attributes | foreach-object {
                    if($_.PositionalArguments)
                    {
                        $potionalArguments=@($_.PositionalArguments |ForEach-Object{$_.toString()})
                    }else
                    {
                        $potionalArguments=$null
                    }
                    @{
                        'TypeName'=$_.TypeName.ToString();
                        'PositionalArguments'=$potionalArguments;
                        'NamedArguments'=@($_.NamedArguments|foreach-object {$index=0}{@{Index=($index++);ArgumentName=$_.ArgumentName;Argument=$_.Argument}})
                     }
                  })
               }
            })
          }
      }

      # 1. if attribute name -clike validateSet then has PositionalArguments and list(option)
      # 2. if alias value -clike 'FilePath' is file
      # 3. if defaultValue value as wap with comma

    #>
}