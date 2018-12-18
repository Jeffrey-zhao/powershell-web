function Create-DependentJobs
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    [Alias()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $ServiceName,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [string]
        $NamePrefix,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [datetime]
        $ScheduledTime,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [int]
        $RelativeStartIntervalMins,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [hashtable]
        $PatchOptions,

        [Parameter(mandatory=$false)]
        [String] $OutputFile,

        [Parameter(Mandatory=$true, ParameterSetName="HeadTemplate")]
        [ValidateNotNullOrEmpty()]
        [string[]] $HeadTemplateNames
    )

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

$newTemplates=@{}

    $getDependentTemplates={
        param($template)

        if($null -ne $template)
        {
            if($template.Id -in $headTemplateIds)
            {               
                return $true
            }

            if(![string]::IsNullOrEmpty($template.DependentTemplates))
            {
                $depedentTemplateIds=$template.DependentTemplates.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
                $temp=$headTemplateIds |Where-Object {$_ -in $depedentTemplateIds}
                if($null -ne $temp -and $temp.count -gt 0)
                {
                    return $true
                }
            }

            $flag=$false
            foreach($dependentTemplateId in $depedentTemplateIds)
            {
                $dependentTemplate = $templates.Values | ForEach-Object {$_} | ?{$_.Id -eq $dependentTemplateId}
                $flag=$flag -or (Invoke-Command -ScriptBlock $getDependentTemplates -ArgumentList $dependentTemplate)
            }
            return $flag
        }
        else
        {
            return $false
        }
   }
   #Determine if there is a dependency between
   $hasDependentShip={
        param($template)
        
        if(![string]::IsNullOrEmpty($template.DependentTemplates))
        {
            $depedentTemplateIds=$template.DependentTemplates.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
            $temp=$leftIds |Where-Object {$_ -in $depedentTemplateIds}
            if($null -ne $temp -and $temp.count -gt 0)
            {
                return $true
            }

            $flag=$false
            foreach($dependentTemplateId in $depedentTemplateIds)
            {
                $dependentTemplate = $templates.Values | ForEach-Object {$_} | ?{$_.Id -eq $dependentTemplateId}
                $flag=$flag -or (Invoke-Command -ScriptBlock $hasDependentShip -ArgumentList $dependentTemplate)
            }
            return $flag

        }
        else{
            return $false
        }
    }

    #generate new templates'chain by HeadTemplate
    if($null -ne $HeadTemplateNames -and $HeadTemplateNames.Count -gt 0){

        $HeadTemplateNames =$HeadTemplateNames |select -Unique

        $HeadTemplates=$Templates.Values |ForEach-Object {$_} | Where-Object {$_.Name -in $HeadTemplateNames}
        $headTemplateIds=$HeadTemplates.Id
        $mixTemplatesIds=$headTemplateIds

        if($null -eq $headTemplateIds -or $headTemplateIds.count -le 0){
            Write-Error "please press valid dependent template names in Service : $Service"
            return $null
        }

        foreach($template in $headTemplates)
        {
            $leftIds=$headTemplateIds |Where-Object{ $_ -ne $template.Id}
            $ret=Invoke-Command -ScriptBlock $hasDependentShip -ArgumentList $template
            if($ret)
            {
                $mixTemplatesIds=$mixTemplatesIds |Where-Object{ $_ -ne $template.Id}
            }
        }

        $headTemplateIds=$mixTemplatesIds

        foreach($templateUnionKey in $templates.Keys)
        {
            $templateUnion = $templates[$templateUnionKey]
            foreach($template in $templateUnion)
            {
                $ret=Invoke-Command -ScriptBlock $getDependentTemplates -ArgumentList $template
                if($ret)
                {
                   if($template.Id -in $headTemplateIds)
                   {
                        $Template.DependentTemplates=','
                   }
                   $newTemplates[$templateUnionKey]+=@($template)
                }
            }
        }
        #optimize dependentjobs that are not in new templates
        foreach($templateUnionKey in $newTemplates.Keys)
        {
            $templateUnion = $newTemplates[$templateUnionKey]
            foreach($template in $templateUnion)
            {
                if(![string]::IsNullOrEmpty($template.DependentTemplates))
                {
                    $depedentTemplateIds=$template.DependentTemplates.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
                    $dependentJobs=($depedentTemplateIds |?{$templateUnion.Id -contains $_}) -join ','
                    $template.DependentTemplates=if([string]::IsNullOrEmpty($dependentJobs)){ $dependentJobs+','} else {$dependentJobs}
                }
            }
        }

        $templates=$newTemplates
    }
    

    $PatchOptionsJson = $null
    try
    {
        if(($PatchOptions -ne $null) -and ($PatchOptions.Count -gt 0))
        {
            $optionArray = @()
            $PatchOptions.Keys | % {$optionArray += @{Key = $_
                                                      Value=$PatchOptions.Item($_)}}
            $PatchOptionsJson = ConvertTo-Json $optionArray
        }
    }
    catch
    {
        Write-Warning "Failed to generate patch options"
        Write-Warning $_
    }

    $script:createdJobIds = @{}

    $scriptBlockCreateJob = $null

    $scriptBlockCreateJob = 
    {
        param($template)

        foreach($serverList in $template.ServerLists)
        {
            $job = New-Object Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJob
            $job.TemplateId = $template.Id
            $job.SelectedServerList = $serverList.Name
            if([string]::IsNullOrEmpty($NamePrefix))
            {
                $job.Name = [string]::Format("{0}_{1}", $template.Name, $serverList.Name)
            }
            else
            {
                $job.Name = [string]::Format("{0}_{1}_{2}", $NamePrefix, $template.Name, $serverList.Name)
            }

            $isRootJob = $false;
            if([string]::IsNullOrEmpty($template.DependentTemplates))
            {
                #This is first job which has no dependency
                $isRootJob = $true
            }
            else
            {
                $dependentTemplateIds = $template.DependentTemplates.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
                $commonIds = $dependentTemplateIds | where {$templateIdsInUnion -contains $_}
                if(($commonIds -eq $null) -or ($commonIds.Count -le 0))
                {
                    #This is first job which has no dependency    
                    $isRootJob = $true
                }
            }

            $dependentJobs = @()

            if($isRootJob)
            {
                $job.ScheduledDateTime = $ScheduledTime
            }
            else
            {
                $job.RelativeTimeInMinutes = [string]$RelativeStartIntervalMins

                $dependentJobIds = @()
                foreach($dependentTemplateId in $template.DependentTemplates.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries))
                {
                    $dependentTemplate = $templates.Values | ForEach-Object {$_} | ?{$_.Id -eq $dependentTemplateId}
					
					if($dependentTemplate -ne $null) #The dependent template would reside in another service that should not be considered here
					{
					    if(!($script:createdJobIds.ContainsKey($dependentTemplate.Id)))
						{
							Invoke-Command $scriptBlockCreateJob -ArgumentList $dependentTemplate
						}
						$dependentJobIds += $script:createdJobIds[$dependentTemplate.Id].JobId
						$dependentJobs += $script:createdJobIds[$dependentTemplate.Id]
					}
                }

                if(($dependentJobIds -ne $null) -and ($dependentJobIds.Count -gt 0))
                {
                    $job.DependentJobs = $dependentJobIds -join ","
                }
            }

            if([string]::IsNullOrEmpty($job.DependentJobs))
            {
                $job.DependentJobs = ","
            }

            if([string]::IsNullOrEmpty($job.RelativeTimeInMinutes) -and ($job.ScheduledDateTime -eq $null))
            {
                $job.ScheduledDateTime = [datetime]::Now
            }

            if(![string]::IsNullOrEmpty($PatchOptionsJson))
            {
                $job.PatchOptions = $PatchOptionsJson
            }

            $createdJob = New-PatJobs -AuthenticationContext $context -ServiceId $template.ServiceId -Job $job

            if($script:createdJobIds.ContainsKey($template.Id))
            {
                $script:createdJobIds[$template.Id] += @{"JobId" = $createdJob.Id
                                                         "ServiceId" = $template.ServiceId
                                                         "DependentJobs" = $dependentJobs}
            }
            else
            {
                $script:createdJobIds[$template.Id] = @(@{"JobId" = $createdJob.Id
                                                        "ServiceId" = $template.ServiceId
                                                        "DependentJobs" = $dependentJobs})
            }
        }
    }

    $jobBulkCollection = @{}

    foreach($templateUnionKey in $templates.Keys)
    {
        $templateUnion = $templates[$templateUnionKey]
        $templateIdsInUnion = $templateUnion | Select -ExpandProperty Id
        $dependentTemplateIds = $templateUnion | Select -ExpandProperty DependentTemplates | ForEach-Object {$_.Split(',')} | ?{![string]::IsNullOrEmpty($_)}

        $templatesNotInDependent = $templateUnion | ?{$_.Id -notin $dependentTemplateIds}

        foreach($template in $templatesNotInDependent)
        {
            Invoke-Command $scriptBlockCreateJob -ArgumentList $template
        }

        $jobBulkKey = $templateUnionKey.ToString()

        $jobBulkCollection[$jobBulkKey] = @()
        foreach($templateId in $templateIdsInUnion)
        {
            $jobBulkCollection[$jobBulkKey] += $script:createdJobIds[$templateId]
        }
    }

    $jobBulkCollection

    $recordsFolder = ".\JobBulkRecords"

    if ((Test-Path -Path $recordsFolder) -eq $False)
    {
        New-Item -Path $recordsFolder -ItemType directory | Out-Null
    }

    if([string]::IsNullOrEmpty($OutputFile))
    {
        if([string]::IsNullOrEmpty($NamePrefix))
        {
            $nowString = $(get-date).ToString("yyyyMMddHHmmss")
            $OutputFile = "$($recordsFolder)\BulkJobs_$($nowString).json"
        }
        else
        {
            $OutputFile = "$($recordsFolder)\$($NamePrefix).json"
        }
    }

    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    $ps_js.Serialize($jobBulkCollection) | Out-File -FilePath $OutputFile
}