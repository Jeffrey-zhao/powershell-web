<#	
	IMPORTANT: YOU NEED TO RUN THE POWERSHELL PROMPT AS ADMINISTRATOR IN ORDER TO UPDATE TEMPLaTES WITH 'SERVERS' PAREMETER	
	           you first need import some related dll files
	.PREREQUISITE
		1.SkwConfig.config
		2.PAT api dlls
			log4net.dll
			Microsoft.IdentityModel.Clients.ActiveDirectory.dll
			Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll
			Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.dll
			Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.UI.dll
			Microsoft.UniversalStore.IamDev.Common.dll
			Microsoft.UniversalStore.IamDev.HttpClient.Common.dll
			Newtonsoft.Json.dll
    .DESCRIPTION
		The important steps for this function
            1. Get Skw config
			2. Get all jobs in patch cycle by calling api
			3. change and save jobs 
	
    .EXAMPLE
		1.update filter jobs scheduledDateTime
         import-module .\UpdateJobsInPatchCycle.ps1 -Force
		 Update-PatchCycleJobs -ServiceName 'Corpnet' -TemplateName 'Sample_Checking_Purpose_PATv2' -PatchCycle '07/2018' -PostponeDays 2 -ExcludeWeekend $true -Timezone 'China Standard Time'
#>

Function Update-PatchCycleJobs
{
    Param(
        #The needed update Service 
        [Parameter(mandatory=$true)]
	    [String] $ServiceName,

         #The needed postpone days considering weekend
        [Parameter(mandatory=$true,
                    ParameterSetName="PostponeDays")]
        [ValidatePattern('[0-9]')]
        [string] $PostponeDays,

        # Parameter help description
        [Parameter(mandatory=$true,
                    ParameterSetName="PostponeDays")]
        [string] $Timezone='China Standard Time',

        # Parameter help description
        [Parameter(mandatory=$true,
                    ParameterSetName="PostponeDays")]
        [bool] $ExcludeWeekend,

        #The needed update Template Name
        [Parameter(mandatory=$false)]
        [string] $TemplateName,

	    #The needed update PatchCycle format 'MM/yyyy' (ie.'05/2015')
        #available breaks "/" 
        [ValidatePattern("^(0[1-9]|1[012])/(\d{4})$")]
        [Parameter(mandatory=$true)]
	    [String] $PatchCycle,

        [Parameter(mandatory=$false)]
        [ValidateSet("Scheduled")]
        [string] $JobType="Scheduled"
    )
    
	try
	{  
        #1. get all related jobs      
        $jobs=@()
        $filterJobs=@()

        #get patchCycle date
        $dtPatchCycle=[datetime]$PatchCycle
        $now=[Datetime]::UtcNow
        #for schedule
        $month=($dtPatchCycle.Year -$now.Year)*12 +$dtPatchCycle.Month-$now.Month+1
        $currentPatchCycle=Get-PatchCycleDate -PatchCycle $dtPatchCycle
        $nextPatchCycle=Get-PatchCycleDate -PatchCycle $dtPatchCycle.AddMonths(1)

        #get all services
        $Services=Get-AvailablePatServices -AuthenticationContext $context
        $Service=$Services |Where-Object{$_.Name -eq $ServiceName}

        Write-Host "Step2: start calling api to get related jobs" -ForegroundColor Green

        if($JobType -eq 'Scheduled')
        {
            if($now.AddMonths($month-1) -gt $currentPatchCycle)
            {
                #get the rest jobs not in patch cyle (when current schedule date is greater than current PatchCycle)
                $jobs += Get-PatJobs -Service $Service.Id -JobType $JobType.ToLower() -Month ($month-1) -AuthenticationContext $context -Verbose
            }
            $jobs += Get-PatJobs -Service $Service.Id -JobType $JobType.ToLower() -Month $month -AuthenticationContext $context
            if($now.AddMonths($month) -lt $nextPatchCycle)
            {
                #get the rest jobs not in patch cyle (when current schedule date is less than next PatchCycle)
                $jobs += Get-PatJobs -Service $Service.Id -JobType $JobType.ToLower() -Month ($month + 1) -AuthenticationContext $context -Verbose
            }
        }
        Write-Host "Step2: get jobs successfully " -ForegroundColor Green
        
        #2. filter and update filtered jobs
        Write-Host "Step3: start to change jobs and update them" -ForegroundColor Green
        $filterJobs=@()
        
        if($JobType -eq 'Scheduled')
        {
            if(![string]::IsNullOrEmpty($TemplateName)){
                $filterJobs+=$jobs |Where-Object {$_.Template.Name -eq $TemplateName -and $_.ScheduledDateTime -ge $currentPatchCycle -and $_.ScheduledDateTime -lt $nextPatchCycle -and $_.ScheduledDateTime -gt $now}
            }
            else{
                $filterJobs+=$jobs |Where-Object {$_.ScheduledDateTime -ge $currentPatchCycle -and $_.ScheduledDateTime -lt $nextPatchCycle -and $_.ScheduledDateTime -gt $now}
            }
            if(![string]::IsNullOrEmpty($PostponeDays)){
                foreach($job in $filterJobs){
                    $convertTime=[System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($job.ScheduledDateTime,'UTC',$Timezone)
                    $postponeDatetime=Get-PostponedDateTime -Datetime $convertTime -Days $PostponeDays -ExcludeWeekend $ExcludeWeekend
                    $job.ScheduledDateTime=[System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($postponeDatetime,$Timezone,'UTC')
                }
            }
        }     
               
        #3. save filter jobs for user checking
        if($filterJobs.count -le 0)
        {
            Write-Host "Step3: the count of filterJobs is 0,and not update any" -ForegroundColor Yellow    
            return
        }else
        {
            $folder='NeedToUpdateJobs'
            if(-not (Test-Path -Path $folder))
            {
                New-Item -Path $folder -ItemType Directory |Out-Null
            }

            $filterJobs > "$folder\$(Get-Date -Format "yyyyMMddHHmmss").txt"
            Write-Host "Step3: the count of filterJobs is :$($filterJobs.count)" -ForegroundColor Yellow
        }
        
        $errorCount=0
        if($JobType -eq 'Scheduled')
        {
            foreach($job in $filterJobs)
            {
               $ret=Set-PatScheduledJob -Service $Service.Id -Id $job.Id -ScheduledDateTime $job.ScheduledDateTime  -AuthenticationContext $context -ErrorAction Continue
               if(-not $ret)
               {
                   $errorCount=$errorCount+1
                   Write-Host "update failed. Server Id: $($Service.Id) Job id: $($job.id)" -ForegroundColor Red
               }
            }
        }

        if($errorCount -le 0)
        {
           Write-Host "Step3: update jobs successfully" -ForegroundColor Green
        }else
        {
           Write-Host "Step3: update jobs but the count :$errorCount ones failed"  -ForegroundColor Red    
        }      
       
            
	} catch
	{
		Write-Host "Error: steps encounter errors:$($_.Exception.Message)" -ForegroundColor Red
	}
}

# list all available timezone
Function Get-TimeZone
{
    Write-Host "search the TimeZone you want, and choose 'Id' as Parameter "
    [System.TimeZoneInfo]::GetSystemTimeZones()
}

#get postponed datetime
Function Get-PostponedDateTime
{
    param(
        [parameter(mandatory=$true)][datetime] $Datetime,
        [parameter(mandatory=$true)][int] $Days,
        [bool] $ExcludeWeekend
    )
    $temp=$Datetime
        if($ExcludeWeekend){
            $i=0
            while($true){
                $i++
                $temp=$temp.AddDays(1)
                if($temp.DayOfWeek -eq 6 -or $temp.DayOfWeek -eq 0){
                    $i--
                }
                if($i -ge $Days){
                    break
                }
            }
        }else{
            $temp=$temp.AddDays($Days)
        }
        return $temp
}
#get per month's PatchCycle date
Function Get-PatchCycleDate
{
    Param(
        #The needed update  patchCycle 
        [Parameter(mandatory=$true)]
        [datetime] $PatchCycle
    )

    $firstDayOfMonth=Get-Date -Year $PatchCycle.Year -Month $PatchCycle.Month -Day 1
    if($firstDayOfMonth.DayOfWeek -le [DayOfWeek]::Tuesday)
    {
        $addDay=7
    }else
    {
        $addDay=14
    }

    return $firstDayOfMonth.AddDays($addDay+[DayOfWeek]::Tuesday-$firstDayOfMonth.DayOfWeek)
}