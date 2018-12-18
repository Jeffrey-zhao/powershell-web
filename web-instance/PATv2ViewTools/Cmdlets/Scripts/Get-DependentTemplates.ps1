function Get-DependentTemplates
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $ServiceName,

        [Parameter(mandatory=$false)]
        [String] $OutputFile
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

        $templates = Get-PatTemplates -AuthenticationContext $context -ServiceId $ServiceId -DependentHierarchy $true
    
        if(($templates -eq $null) -or ($templates.Values.Count -le 0))
        {
            Write-Warning "No jobs created since no templates have dependency"
            return $null
        }
       $Script:AllTemplates=@()
       $Script:dependentTemplates=@()
       $getDependentTemplatesList={
            param($template)

            $hastemplate=$Script:AllTemplates|Where-Object{$_.Id -eq $template.Id}
            if($null -eq $hastemplate)
            {
                $Script:AllTemplates+=@{Id=$template.Id;TemplateName=$template.Name}
            }

            if(![string]::IsNullOrEmpty($template.DependentTemplates))
            {
                $depedentTemplateIds=$template.DependentTemplates.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)

                foreach($dependentTemplateId in $depedentTemplateIds)
                {
                    $dependentTemplate = $templates.Values | ForEach-Object {$_} | ?{$_.Id -eq $dependentTemplateId}
                    $hasdependencies=$Script:dependentTemplates |Where-Object{$_.Id -eq $template.Id -and $_.PredeccessorId -eq $dependentTemplate.Id}
                    if($null -eq $hasdependencies)
                    {
                        $Script:dependentTemplates+=@{Id=$template.Id;TemplateName=$template.Name;PredeccessorId=$dependentTemplate.Id;PredeccessorTemplateName=$dependentTemplate.Name}
                    }

                    Invoke-Command -ScriptBlock $getDependentTemplatesList -ArgumentList $dependentTemplate
                }
            }
        }

        foreach($templateUnionKey in $templates.Keys)
        {
            $templateUnion = $templates[$templateUnionKey]
            $templateIdsInUnion = $templateUnion | Select -ExpandProperty Id
            $dependentTemplateIds = $templateUnion | Select -ExpandProperty DependentTemplates | ForEach-Object {$_.Split(',')} | ?{![string]::IsNullOrEmpty($_)}

            $templatesNotInDependent = $templateUnion | ?{$_.Id -notin $dependentTemplateIds}

            foreach($template in $templatesNotInDependent)
            {
                Invoke-Command $getDependentTemplatesList -ArgumentList $template
            }
        }
        
        $dependentSet=@{Templates=$Script:AllTemplates;Dependencies=$Script:dependentTemplates}
        $recordsFolder = ".\DependentTemplatesJsonFolder"

        if ((Test-Path -Path $recordsFolder) -eq $False)
        {
            New-Item -Path $recordsFolder -ItemType directory | Out-Null
        }

        if([string]::IsNullOrEmpty($OutputFile))
        {
            $nowString = $(get-date).ToString("yyyyMMddHHmmss")
            $OutputFile = "$($recordsFolder)\$nowString.json"
        }

        add-type -assembly system.web.extensions
        $ps_js=new-object system.web.script.serialization.javascriptSerializer
        $ps_js.Serialize($dependentSet) | Out-File -FilePath $OutputFile
        Write-Host "Get Template Dependencies successfully and a json file saved in path: $OutputFile " -ForegroundColor Green
   }catch
   {
        Write-Error $_
   }
}