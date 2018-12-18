<#
 .EXAMPLE
 #FilePath content format: add server and template per line ,should split them with comma(,) not need addtional space
 server1,template1
 server2,template1
 server3,template2
  Create-AdhocDependentJobs -ServiceName Corpnet -NamePrefix 'mytest' -ServerListFile 'serverlist.txt' -PatchOptions @{'-QFE'='kb12345';'-ListOnly'=''} -ScheduledTime '2018/09/20 12:00:00' -OutputFile 'mytest.json'
#>
function Create-AdhocDependentJobs
{
    [CmdletBinding()]
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

		[Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ServerListFile,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [datetime]
        $ScheduledTime,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [int]
        $RelativeStartIntervalMins,
        
        [parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [hashtable]
        $PatchOptions,

        [Parameter(mandatory=$false)]
        [String] $OutputFile
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

    $templatesOrigin = Get-PatTemplates -AuthenticationContext $context -ServiceId $ServiceId -DependentHierarchy $true

    if(($templatesOrigin -eq $null) -or ($templatesOrigin.Values.Count -le 0))
    {
        Write-Warning "No jobs created since no templates have dependency"
        return $null
    }

    $fileTemplates=ReadFileToDirectory -FilePath $FilePath
	if(($fileTemplates -eq $null) -or ($fileTemplates.Values.Count -le 0))
    {
        Write-Warning "Cannot get right servers with templates"
        return $null
    }
    $templates=@{}
    foreach($templateKey in $templatesOrigin.Keys)
    {
        $hasTemplates=$templatesOrigin[$templateKey]|?{$fileTemplates.Keys -contains $_.Name}
        if($hasTemplates -ne $null)
        {
            $templates[$templateKey]+=$hasTemplates
        }
    }

    $PatchOptionsJson=$null
    try {
        if($null -ne$PatchOptions -and $PatchOptions.Count -gt 0){
            $optionArray=@()
            $PatchOptions.Keys | %{$optionArray +=@{key=$_;Value=$PatchOptions.Item($_)}}
            $PatchOptionsJson=ConvertTo-Json $optionArray
        }
    }
    catch {
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
            $Servers=@()
			$Servers=$fileTemplates[$template.Name]|?{$serverList.Servers -contains $_}
			if($Servers -eq $null)
			{
				return $null
			}

            $job = New-Object Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJob
            $job.TemplateId = $template.Id
            #$job.SelectedServerList = $serverList.Name
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

                    if(!!$dependentTemplate)
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
                $job.PatchOptions=$PatchOptionsJson
            }
            
            $createdJob = New-PatJobs -AuthenticationContext $context -ServiceId $template.ServiceId -Job $job -Servers $Servers
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

Function ReadFileToDirectory
{
	param(
		[string]$FilePath
	)
	$templateWithServers=@{}
	$errorFlag=$false  # the flag if exists invalid format line
	foreach($line in Get-Content($FilePath))
	{
		if($line -match '\S+[,]\S+')
		{
			$line=$line.split(',',[System.StringSplitOptions]::RemoveEmptyEntries)
            if($templateWithServers[$line[1].trim()] -eq $null)
            {
                $templateWithServers[$line[1].trim()]=@($line[0].trim())
            }
            else
            {
            $templateWithServers[$line[1].trim()]+=@($line[0].trim())
            }
		}
		elseif($line -match '\S+' -and $line -notmatch '[,]') # not empty and not comma
		{
			Write-Warning 'exists invalid format line in $FilePath'
			return $null
		}
	}
	return $templateWithServers
}