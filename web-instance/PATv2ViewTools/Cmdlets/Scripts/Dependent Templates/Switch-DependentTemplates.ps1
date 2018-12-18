<#
.Synopsis
   it updates cross-environment dependencies 
.EXAMPLE
   Switch-DependentTemplates -ServiceNames 'Corpnet','ServicePATTest'
.EXAMPLE
   Switch-DependentTemplates -ServiceNames 'Corpnet','ServicePATTest' -DeleteDependencies 'template1','template2'
.NOTES
   before updating you should make sure dependencies is correct in the same environment on the portal
#>
Function Switch-DependentTemplates
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $ServiceNames,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [string]
		$EnvFileFolder='.\EnvironmentFilesFolder',

		#cross env dependencies
		# '->' means cross-environment dependency, 
		# ',' indicates partitioning of multiple dependencies
		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
		[string]
		$EnvDependencies='Prod->Int,AlwaysProd->Prod,Dr->AlwaysProd',
        
        #when remove a template from a env-file,its dependencies need to be deleted
		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
		[string[]]
		$DeletedTemplateNames
    )
    try
    {
	    $availableServices=Get-AvailablePatServices -AuthenticationContext $context
        $Services=($availableServices |Where-Object{$_.Name -in $ServiceNames})

	    if($Services -eq $null -or $Services.Count -le 0)
	    {
		    Write-Warning "please input a valid Service Names"
		    return $null
	    }else
	    {
		    $ServiceIds=$Services.Id
	    }

		$ServiceTemplates=@()
		foreach($ServiceId in $ServiceIds)
		{
			$ServiceTemplates+=get-PatTemplates -ServiceId $ServiceId -AuthenticationContext $context
		}

		$fileTemplates=@()
        $EnvFiles = Get-ChildItem $EnvFileFolder    
		if($null -ne $EnvFiles -and $EnvFiles.Count -gt 0)
		{			
			foreach($File in $EnvFiles)
			{
				$fileName=$file.Name.Split('.')[0]
				$templateNames=Get-Content $File.FullName |Where-Object {![string]::IsNullOrEmpty($_)};
				if ($null -eq $templateNames -or $templateNames.Count -le 0)
				{
					Write-Warning "$File is empty,please check it..."
					return $null
				}
				switch ($fileName)
				{
					"Int" { 
						 $fileTemplates+=@{Env="Int"; TemplateNames=$templateNames;Templates=@();HeadTemplates=@();TailTemplates=@()}						 
					}
					"Prod" {
						 $fileTemplates+=@{Env="Prod"; TemplateNames=$templateNames;Templates=@();HeadTemplates=@();TailTemplates=@()}
					}
					"AlwaysProd" {
						$fileTemplates+=@{Env="AlwaysProd"; TemplateNames=$templateNames;Templates=@();HeadTemplates=@();TailTemplates=@()}
					}
					"Dr" {
						$fileTemplates+=@{Env="Dr"; TemplateNames=$templateNames;Templates=@();HeadTemplates=@();TailTemplates=@()}
					}
				}
			}
		}        
        
        foreach($fileTemplate in $fileTemplates)
        {
            foreach($templateName in $fileTemplate.TemplateNames)
			{
				$template= $ServiceTemplates |Where-Object {$_.Name -eq $templateName}
				if($null -ne $template)
				{
					$fileTemplate.Templates+=$template
				}
				else
				{
					Write-Warning "template ($templateName) you provided in files are not found in your given services..."
					return $null
				}
			}           
        }     
   
        foreach($fileTemplate in $fileTemplates)
	    {  
            #remove dependencies in group env
            $otherGroupTemplateIds=$fileTemplates |Where-Object {$_.Env -ne $fileTemplate.Env} |ForEach-Object{$_.Templates.Id}
		    foreach($template in $fileTemplate.Templates)
		    {
                if($null -ne $template.DependentTemplates -and ![string]::IsNullOrEmpty($template.DependentTemplates.trim(',')))
                {
                    $dependentIds=$template.DependentTemplates.Split(',')
                    $dependencies=$dependentIds |Where-Object {$_ -notin $otherGroupTemplateIds}
                    if($null -ne $dependencies -and $dependencies.Count -gt 0)
					{
						$template.DependentTemplates= $dependencies -join ','
					}else
                    {
                        $template.DependentTemplates= ','
                    }
                }
		    }
        }

		foreach($fileTemplate in $fileTemplates)
		{         
            foreach($template in $fileTemplate.Templates)
            {
				if($null -ne $template.DependentTemplates -and ![string]::IsNullOrEmpty($template.DependentTemplates.trim(',')))
				{
					$dependentTemplates=$template.DependentTemplates.Split(',')|Where-Object{$_ -in $fileTemplate.Templates.Id}
					if($null -eq $dependentTemplates -or $dependentTemplates.Count -le 0)
					{
						$fileTemplate.HeadTemplates+=$template
					}
				}else
				{
					$fileTemplate.HeadTemplates+=$template
				}				
			}

            $dependentIds=$fileTemplate.Templates |Where-Object {$null -ne $_.DependentTemplates -and ![string]::IsNullOrEmpty($_.DependentTemplates.trim(','))} |
				ForEach-Object {$_.DependentTemplates.Split(',')}

			$fileTemplate.Templates |ForEach-Object{
				if($_.Id -notin $dependentIds){$fileTemplate.TailTemplates+=$_}
			}

			if($null -ne $DeletedTemplateNames -and $DeletedTemplateNames.Count -gt 0)
			{
				#headTemplates
				if($fileTemplate.HeadTemplates |Where-Object {$_.Name -in $DeletedTemplateNames})
				{
					#remove delete templates from head templates
					$temp=$fileTemplate.HeadTemplates |Where-Object {$_.Name -notin $DeletedTemplateNames}
					$fileTemplate.HeadTemplates=@()
					$fileTemplate.HeadTemplates+=$temp

					#add new templates as head templates
					$remainTemplates=$fileTemplate.Templates |Where-Object {$_.Name -notin $DeletedTemplateNames}
					foreach($templateName in $DeletedTemplateNames)
					{
						$deletedTemplateId=$fileTemplate.Templates |Where-Object {$_.Name -eq $templateName}
						$remainTemplates |Where-Object {$null -ne $_.DependentTemplates}|ForEach-Object{
							$dependentIds=$_.DependentTemplates.Split(',')
							if($dependentIds.Count -eq 1 -and $dependentIds[0] -eq $deletedTemplateId){
								$fileTemplate.HeadTemplates+=$_
							}
					    }
				    }
                }

				#tailTemplates
				if($fileTemplate.TailTemplates |Where-Object {$_.Name -in $DeletedTemplateNames})
				{
					#remove delete templates from tail templates
					$temp=$fileTemplate.TailTemplates |Where-Object {$_.Name -notin $DeletedTemplateNames}
					$fileTemplate.TailTemplates=@()
					$fileTemplate.TailTemplates+=$temp

					#add new templates as tail templates
					$remainTemplates=$fileTemplate.Templates |Where-Object {$_.Name -notin $DeletedTemplateNames}
					$dependentIds=$remainTemplates|Where-Object{ $null -ne $_.DependentTemplates -and ![string]::IsNullOrEmpty($_.DependentTemplates.trim(','))} |
						ForEach-Object {$_.DependentTemplates.Split(',')}

					$remainTemplates |ForEach-Object{
						if($_.Id -notin $dependentIds -and $_.Id -notin $fileTemplate.TailTemplates.Id){$fileTemplate.TailTemplates+=$_}
					}
				}
			}           
		}     

	    #update templates' dependencies for diffrent envinments
	    Set-EnvDependencies -FileTemplates $fileTemplates -EnvDependencies $EnvDependencies
	    $updateTemplates=@()
		$fileTemplates|ForEach-Object {$updateTemplates+=$_.Templates}
		foreach($template in $updateTemplates)
		{
			Set-PatTemplate -ServiceId $template.ServiceId -Template $template -AuthenticationContext $context |Out-Null
		}

        Write-Host 'Update Template Dependencies successfully ...' -ForegroundColor Green

     }catch
     {
        Write-Error $_
     }
}

Function Set-EnvDependencies
{
	param(
        $FileTemplates,
		$EnvDependencies
	)

	$orders=$EnvDependencies.Split(',')
	for($i=0;$i -lt $orders.Length; $i++)
	{
		$envs=$orders[$i].Split('->')
		$preTemplates=$fileTemplates |Where-Object {$_.Env -eq $envs[0]}
		$nextTemplates=$fileTemplates |Where-Object {$_.Env -eq $envs[2]}

		$dependencies=$nextTemplates.TailTemplates.Id -join ','
		$preTemplates.HeadTemplates|ForEach-Object {
			if($null -eq $_.DependentTemplates -or [string]::IsNullOrEmpty($_.DependentTemplates.trim(',')))
			{
				$_.DependentTemplates=$dependencies
			}else
			{
				$_.DependentTemplates += ',' + $dependencies	
			}			
		}				
	}
}