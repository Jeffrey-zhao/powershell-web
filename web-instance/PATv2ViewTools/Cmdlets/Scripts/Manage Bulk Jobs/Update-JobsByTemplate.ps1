<#		
    .EXAMPLE
		1.update jobs scheduledDateTime with some templates
         import-module .\UpdateJobsInPatchCycle.ps1 -Force
		 Update-JobsByTemplate -ServiceName ServicePATTest -FilePath .\FileTemplate.txt
#>

Function Update-JobsByTemplate {
    Param(
        #The needed update Service 
        [Parameter(mandatory = $true)]
        [String] $ServiceName,

        #The needed update Template Name
        [Parameter(mandatory = $true)]
        [string] $FilePath,

        #The needed update PatchCycle format 'MM/yyyy' (ie.'05/2015')
        #available breaks "/" 
        [ValidatePattern("^(0[1-9]|1[012])/(\d{4})$")]
        [Parameter(mandatory = $false)]
        [String] $PatchCycle=[datetime]::UtcNow.ToString('MM/yyyy')
    )
    
    try {  
        #get all services
        $Services = Get-AvailablePatServices -AuthenticationContext $context
        $Service = $Services |Where-Object {$_.Name -eq $ServiceName}
        if($null -eq $service){
            Write-Warning "your given service name doesn't exists,please check it..."
            return $null
        }
        $fileTemplates=@()
        if(Test-Path -Path $FilePath)
        {
            $templates=Get-Content -Path $FilePath |Where-Object {![string]::IsNullOrEmpty($_)}
            if ($null -eq $templates -or $templates.Count -le 0)
            {
                Write-Warning "$FilePath is empty,please check it..."
                return $null
            }
            else
            {
                $templates |foreach-object {$templateInfo=$_.split(',');$fileTemplates+=@{TemplateName=$templateInfo[0];ScheduledDateTime=$templateInfo[1]}}               
            }
        }else
        {
            Write-Warning "your given FilePath doesn't exist,please check it..."
        }
        #2. filter jobs
        $filterJobs=@()
        if($templates.Count -gt 0)
        {
            $activeJobs += Get-JobsByPatchCycle -ServiceId $Service.Id -PatchCycle $PatchCycle -JobType 'active'
            $scheduledJobs += Get-JobsByPatchCycle -ServiceId $Service.Id -PatchCycle $PatchCycle -JobType 'scheduled'
    
            $templateIds = $fileTemplates.TemplateName
            $filterJobs += $activeJobs |Where-Object {$_.Template.Name -in $templateIds -and $null -ne $_.SelectedServerList}
            $filterJobs += $scheduledJobs |Where-Object {$_.Template.Name -in $templateIds -and $null -ne $_.SelectedServerList -and $null -ne $_.ScheduledDateTime}
        }
        
        #3. update job schedule datetime
        $updateJobs=@()
        foreach($templateInfo in $fileTemplates)
        {
            $filterJobs |Where-Object {$_.Template.Name -eq $templateInfo.TemplateName}|foreach-object{$_.ScheduledDateTime=$templateInfo.ScheduledDateTime;$updatejobs+=$_}
        }

        #4. save filter jobs into db       
        $errorCount = 0
        foreach ($job in $updateJobs) {
            $ret = Set-PatScheduledJob -Service $Service.Id -Id $job.Id -ScheduledDateTime $job.ScheduledDateTime  -AuthenticationContext $context -ErrorAction Continue
            if (-not $ret) {
                $errorCount = $errorCount + 1
                Write-Host "update failed. Server Id: $($Service.Id) Job id: $($job.id)" -ForegroundColor Red
            }
        }

        if ($errorCount -le 0) {
            Write-Host "Step3: update jobs successfully" -ForegroundColor Green
        }
        else {
            Write-Host "Step3: update jobs but the count :$errorCount ones failed"  -ForegroundColor Red    
        }                
    }
    catch {
        Write-Host "Error: steps encounter errors:$($_.Exception.Message)" -ForegroundColor Red
    }
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