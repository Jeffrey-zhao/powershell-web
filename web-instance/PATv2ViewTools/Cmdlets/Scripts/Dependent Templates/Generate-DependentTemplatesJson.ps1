<#
.Synopsis
   it generates templates' dependencies and their jobs in current patch cycle  
.EXAMPLE
	ipmo .\Generate-DependentTemplatesJson.ps1 -force
	Generate-DependentTemplatesJson -ServiceNames @('Corpnet','CORPNET-KEZ2') -PatchCycle '09/2018' -OutputFile 'test.json'
#>
function Generate-DependentTemplatesJson {
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [validateNotNullOrEmpty()]
        [string[]]$ServiceNames,

        #The needed update PatchCycle format 'MM/yyyy' (ie.'05/2015')
        #available breaks "/" 
        [ValidatePattern("^(0[1-9]|1[012])/(\d{4})$")]
        [Parameter(mandatory = $true)]
        [String] $PatchCycle,

        [Parameter(mandatory = $false)]
        [String] $OutputFile,

		[Parameter(mandatory = $false)]
		[ValidateSet('dist','src')]
        [String] $ReplaceDataPath='dist',

		[Parameter(mandatory = $false)]
		[Switch] $HasTemplatesGroup
    )

    $script:data = @()
    $script:links = @()
    $filterJobs = @()  
    $templatesCollection = @()
    $noDependentIds = @()
    $activeJobs=@()
    $scheduledJobs=@()
    $historyJobs=@()
	$envFileFolder='.\EnvironmentFilesFolder'
	$fileTemplates=@()

    try
    {
        $Services = Get-AvailablePatServices -AuthenticationContext $context
        $availableServices = ($Services |Where-Object {$_.Name -in $ServiceNames})

        if ($null -eq $availableServices -or $availableServices.Count -le 0) {
            throw
        }
    }catch
    {
        Write-Error "Service Name is invalid or account service encounter errors"
        return $null
    }

	if([bool]$HasTemplatesGroup)
	{
		$EnvFiles = Get-ChildItem $envFileFolder    
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
							$fileTemplates+=@{Env="Int"; TemplateNames=$templateNames}						 
					}
					"Prod" {
							$fileTemplates+=@{Env="Prod"; TemplateNames=$templateNames}
					}
					"AlwaysProd" {
						$fileTemplates+=@{Env="AlwaysProd"; TemplateNames=$templateNames}
					}
					"Dr" {
						$fileTemplates+=@{Env="Dr"; TemplateNames=$templateNames}
					}
				}
			}
		}
	}
    #-----------------------------------script block start-----------------------------------------------#
	#get template's group
	$getTemplateGroup={
		param($templateName)

		$group=''
		foreach($fileTemplate in $fileTemplates)
		{
			if($templateName -in $fileTemplate.TemplateNames)
			{
				$group=$fileTemplate.Env
				break
			}
		}
		return $group
	}

    # generate data and links 
    $getDataAndLinksScript = {
        param($template,$datetime)

        if ($null -ne $script:data -and $script:data.Count -gt 0) {
            $tempTemplate = $script:data|Where-Object {$_.id -eq $template.Id}
        }
        if ($null -eq $tempTemplate) {
			if($null -eq $datetime)
			{
				$datetime=[datetime]::UtcNow
			}else
			{
				$datetime=([datetime]$datetime).AddDays(-5)
			}
			$group=''
			$progress=0
			if([bool]$HasTemplatesGroup)
			{
				$group=Invoke-Command -ScriptBlock $getTemplateGroup -ArgumentList $template.Name
				$progress=0.2 
			}
			$script:data += @{id = $template.Id; text = $template.Name; type = "task"; 
				open = $true; start_date = $datetime.ToString("yyyy/MM/dd HH:mm:ss"); duration = 3; progress=$progress;
				custom=@{jobs = @();jobids = '';status = ''; templateids = '';group=$group}
			} 
        }
   
        $dependentTemplateIds = @()
        if ($null -ne $template.DependentTemplates) {   
            $dependentTemplateIds += $template.DependentTemplates.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
        }
        if ($dependentTemplateIds.count -gt 0) {
            foreach ($dependentTemplateId in $dependentTemplateIds) {
                $dependentTemplate = $templatesCollection.Values | ForEach-Object {$_} | ? {$_.Id -eq $dependentTemplateId}
                if ($null -ne $dependentTemplate) {
                    if ($null -ne $script:links -and $script:links.Count -gt 0) {
                        $dependent = $script:links |? {$_.target -eq $template.id -and $_.source -eq $dependentTemplateId}
                    }
                    if ($null -eq $dependent) {
                        $script:links += @{id = 0; source = [int]$dependentTemplateId; target = $template.Id; type = 0}
                        Invoke-Command -ScriptBlock $getDataAndLinksScript -ArgumentList $dependentTemplate,$datetime                    
                    }    
                }                           
            }     
        }        
    }

    #-----------------------------------script block end-----------------------------------------------#
    foreach ($Service in $availableServices) {

        $templatesOrigin = Get-PatTemplates -AuthenticationContext $context -ServiceId $Service.Id -DependentHierarchy $true

        if (($null -eq $templatesOrigin) -or ($templatesOrigin.Values.Count -le 0)) {
            Write-Warning "No jobs created since no templates have dependency"
            return $null
        }

        $templatesCollection += $templatesOrigin
        #add jobs relationship
        $activeJobs += Get-JobsByPatchCycle -ServiceId $Service.Id -PatchCycle $PatchCycle -JobType 'active'
        $scheduledJobs += Get-JobsByPatchCycle -ServiceId $Service.Id -PatchCycle $PatchCycle -JobType 'scheduled'
        $historyJobs += Get-JobsByPatchCycle -ServiceId $Service.Id -PatchCycle $PatchCycle -JobType 'history'       
    }

    #generate template relatetionship 
    foreach ($templateItems in $templatesCollection) {
        foreach ($templateUnionKey in $templateItems.Keys) {
            $templateUnion = $templateItems[$templateUnionKey]
            $dependentTemplateIds = $templateUnion | Select-Object -ExpandProperty DependentTemplates | ForEach-Object {$_.Split(',')} | ? {![string]::IsNullOrEmpty($_)}
        
            $templatesNotInDependent = $templateUnion | Where-Object {$_.Id -notin $dependentTemplateIds}
            $noDependentIds += $templatesNotInDependent

            foreach ($template in $templatesNotInDependent) {
                Invoke-Command $getDataAndLinksScript -ArgumentList $template,$null
            }
        }
    }

    $templateIds = $templatesCollection.Values.Id 
    $filterJobs += $activeJobs |Where-Object {$_.TemplateId -in $templateIds -and $null -ne $_.SelectedServerList}
    $filterJobs += $scheduledJobs |Where-Object {$_.TemplateId -in $templateIds -and $null -ne $_.SelectedServerList -and $null -ne $_.ScheduledDateTime}
    $filterJobs += $historyJobs |Where-Object {$_.TemplateId -in $templateIds -and $null -ne $_.SelectedServerList -and $null -ne $_.ScheduledDateTime} 
   
    #format start_date
    $linkId = 0
    foreach ($link in $script:links) {
        $linkId++
        $link.id = $linkId
    }

    foreach ($item in $script:data) {
        $temp = $filterJobs |Where-Object {$item.Id -eq $_.TemplateId}
        if ($null -ne $temp -or $temp.count -gt 0) {                   
            #jobs
            $temp |ForEach-Object {
                if ($null -ne $_.ScheduledDateTime) {
                    $date = $_.ScheduledDateTime.ToString("yyyy/MM/dd HH:mm:ss")
                } 
                else {$date = ''}
                $item.custom.jobs += @{id     = $_.Id
                    text               = $_.Name
                    start_date         = $date
                    status             = [string]$_.JobStateInfo.State
                    selectedServerList = $_.SelectedServerList
                } 
            }
            #jobids
            $item.custom.jobids = $temp.Id -join ','
            #status
            if ($null -ne $item.custom -and $item.custom.jobs.count -gt 0) {
                $item.custom.status = 'HasJobs'
            }
        }
        else {
            $item.custom.jobs = @()
            $item.custom.status = 'NoJobs'
            $item.text += ''
            $item.custom.jobids = ''
        }
        #templateids
        $script:links | Where-Object { $_.source -eq $item.id} |ForEach-Object {$item.custom.templateids += [string]$_.target + ','}
        $item.custom.templateids = $item.custom.templateids.trim(',')
    }

    $obj = @{data = $script:data; links = $script:links}

    $recordsFolder = ".\DependentTemplatesFolders"

    if ((Test-Path -Path $recordsFolder) -eq $False) {
        New-Item -Path $recordsFolder -ItemType directory | Out-Null
    }

    if ([string]::IsNullOrEmpty($OutputFile)) {
        $nowString = $(get-date).ToString("yyyyMMddHHmmss")
        $OutputFile = "$($recordsFolder)\$nowString.json"
    }
    else {
        $OutputFile = "$($recordsFolder)\$OutputFile"
    }

    add-type -assembly system.web.extensions
    $ps_js = new-object system.web.script.serialization.javascriptSerializer
    #replace content
    $jsonContent=$ps_js.Serialize($obj)
    $jsonContent | Out-File -FilePath $OutputFile
    $jsonContent |Out-File -FilePath ".\PATV2ViewTools\$ReplaceDataPath\data\template.json"   
    Write-Host "generate json file in '$($OutputFile)' sucessfully..." -ForegroundColor Green
}

Function Get-JobsByPatchCycle {
    param(
        [Parameter(Mandatory = $true)]
        [validateNotNullOrEmpty()]
        [string] $ServiceId,

        [ValidatePattern("^(0[1-9]|1[012])/(\d{4})$")]
        [Parameter(mandatory = $true)]
        [String] $PatchCycle,

        [ValidateSet('active', 'scheduled', 'history')]
        [Parameter(mandatory = $true)]
        [String] $JobType
    )
    #get patchCycle date
    $dtPatchCycle = [datetime]$PatchCycle
    $now = [Datetime]::UtcNow
    $month = ($dtPatchCycle.Year - $now.Year) * 12 + $dtPatchCycle.Month - $now.Month + 1
    $currentPatchCycle = Get-PatchCycleDate -PatchCycle $dtPatchCycle
    $nextPatchCycle = Get-PatchCycleDate -PatchCycle $dtPatchCycle.AddMonths(1)

    $tempJobs = @()
    if ($JobType -eq 'active') {
        $jobs = Get-PatJobs -Service $ServiceId -JobType $JobType.ToLower() -AuthenticationContext $context
        $tempJobs+=$jobs |Where-Object {$null -eq $_.ScheduledDateTime -or ($null -ne $_.ScheduledDateTime -and $_.ScheduledDateTime -ge $currentPatchCycle -and $_.ScheduledDateTime -lt $nextPatchCycle)}
    }
    elseif ($JobType -eq 'scheduled') {
        if ($now.AddMonths($month - 1) -gt $currentPatchCycle) {
            #get the rest jobs not in patch cyle (when current schedule date is greater than current PatchCycle)
            $jobs += Get-PatJobs -Service $ServiceId -JobType $JobType.ToLower() -Month ($month - 1) -AuthenticationContext $context
        }
        $jobs += Get-PatJobs -Service $ServiceId -JobType $JobType.ToLower() -Month $month -AuthenticationContext $context
        if ($now.AddMonths($month) -lt $nextPatchCycle) {
            #get the rest jobs not in patch cyle (when current schedule date is less than next PatchCycle)
            $jobs += Get-PatJobs -Service $ServiceId -JobType $JobType.ToLower() -Month ($month + 1) -AuthenticationContext $context
        }
        $tempJobs += $jobs | Where-Object {$_.ScheduledDateTime -ge $currentPatchCycle -and $_.ScheduledDateTime -lt $nextPatchCycle -and $_.ScheduledDateTime -gt $now}
    }
    elseif ($JobType -eq 'history') {
        while ($true) {
            $jobs = Get-PatJobs -Service $ServiceId -JobType $JobType.ToLower() -AuthenticationContext $context
            $temp = $jobs |Where-Object {$null -ne $_.ScheduledDateTime -and $_.ScheduledDateTime -ge $currentPatchCycle -and $_.ScheduledDateTime -lt $nextPatchCycle}
            $tempJobs += $temp
            if ($temp.count -lt $jobs.count) {
                break;
            }
        }
    }
    return $tempJobs
}

#get per month's PatchCycle date
Function Get-PatchCycleDate {
    Param(
        #The needed update  patchCycle 
        [Parameter(mandatory = $true)]
        [datetime] $PatchCycle
    )

    $firstDayOfMonth = Get-Date -Year $PatchCycle.Year -Month $PatchCycle.Month -Day 1
    if ($firstDayOfMonth.DayOfWeek -le [DayOfWeek]::Tuesday) {
        $addDay = 7
    }
    else {
        $addDay = 14
    }

    return $firstDayOfMonth.AddDays($addDay + [DayOfWeek]::Tuesday - $firstDayOfMonth.DayOfWeek)
}
