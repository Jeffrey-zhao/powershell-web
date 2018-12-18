function Update-DependentTemplates
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ServiceName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false)]
        [string]
        $JsonFilePath
    )
    try
    {
	    $Services=Get-AvailablePatServices -AuthenticationContext $context
        $Service=($Services |Where-Object{$_.Name -eq $ServiceName})

	    if($Service -eq $null -or $Service -eq '')
	    {
		    Write-Warning "please input a valid Service Name"
		    return $null
	    }else
	    {
		    $ServiceId=$Service.Id
	    }

        $json = Get-Content $JsonFilePath      
        $jsonDependencies = $json |ConvertFrom-Json            
       
       $newDependencies=$jsonDependencies.Dependencies |Group-Object Id |Select-Object @{l='Id';e={$_.Name}},@{l='DependentTemplates';e={$_.Group.PredeccessorId -join ','}}

       foreach($template in $jsonDependencies.Templates)
       {
            $template=Get-PatTemplate -ServiceId $ServiceId -TemplateId $template.Id -AuthenticationContext $context
            $dependency=$newDependencies |Where-Object {$_.Id -eq $template.Id}
            $template.DependentTemplates=$dependency.DependentTemplates 
            $temp=Set-PatTemplate -ServiceId $ServiceId -Template $template -AuthenticationContext $context
       }

       Write-Host 'Update Template Dependencies successfully ...' -ForegroundColor Green

     }catch
     {
        Write-Error $_
     }
}