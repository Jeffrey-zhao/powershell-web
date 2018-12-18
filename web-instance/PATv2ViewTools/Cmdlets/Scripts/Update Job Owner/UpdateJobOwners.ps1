<#    
    IMPORTANT: YOU NEED TO RUN THE POWERSHELL PROMPT AS ADMINISTRATOR IN ORDER TO UPDATE TEMPLaTES WITH 'SERVERS' PAREMETER    
               you first need import some related dll files
    .PREREQUISITE
        1.PAT api dlls
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
            1. Get all jobs in patch cycle by calling api
            2. change and save jobs with owner 
    
    .EXAMPLE
        1.update filter jobs
         .\UpdateJobOwners.ps1 -ServiceName 'CORPNET-KEZ2' -Owner 'test@microsoft.com'  -TemplateName 'Sample_Checking_Purpose_PATv2' -PatchCycle '07/2018'
#>

[CmdletBinding()]
 Param(
        #The needed update Service 
        [Parameter(mandatory=$true)]
        [String] $ServiceName,

        #The needed update Owner (suggest assigned to Login User or who has permission)
        [Parameter(mandatory=$true)]
        [string] $Owner,

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

Function Update-JobOwners
{
   
    try
    {
        #1. get all related jobs
        Write-Host "Step1: start calling api to get related jobs" -ForegroundColor Green
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

        if($JobType -eq 'Scheduled')
        {
            if($now.AddMonths($month-1) -gt $currentPatchCycle)
            {
                #get the rest jobs not in patch cyle (when current schedule date is greater than current PatchCycle)
                $jobs += Get-PatJobs -ServiceId $Service.Id -JobType $JobType.ToLower() -Month ($month-1) -AuthenticationContext $context -Verbose
            }
            $jobs += Get-PatJobs -ServiceId $Service.Id -JobType $JobType.ToLower() -Month $month -AuthenticationContext $context
            if($now.AddMonths($month) -lt $nextPatchCycle)
            {
                #get the rest jobs not in patch cyle (when current schedule date is less than next PatchCycle)
                $jobs += Get-PatJobs -ServiceId $Service.Id -JobType $JobType.ToLower() -Month ($month + 1) -AuthenticationContext $context -Verbose
            }
        }
        Write-Host "Step1: get jobs successfully" -ForegroundColor Green
        
        #2. filter and update filtered jobs
        Write-Host "Step2: start to change jobs and update them" -ForegroundColor Green
        $filterJobs=@()
        
        if($JobType -eq 'Scheduled')
        {
            $filterJobs+=$jobs |Where-Object {$_.Template.Name -eq $TemplateName -and $_.ScheduledDateTime -ge $currentPatchCycle -and $_.ScheduledDateTime -lt $nextPatchCycle -and $_.ScheduledDateTime -gt $now}
        }     
               
        #save filter jobs for user checking
        if($filterJobs.count -le 0)
        {
            Write-Host "Step2: the count of filterJobs is 0,and not update any" -ForegroundColor Yellow    
            return
        }else
        {
            $filterJobs > "NeedToUpdateJobs_$(Get-Date -Format "yyyyMMddHHmmss").txt"
            Write-Host "Step2: the count of filterJobs is :$($filterJobs.count)" -ForegroundColor Green
        }
        
        $errorCount=0
        if($JobType -eq 'Scheduled')
        {
            foreach($job in $filterJobs)
            {
               $ret=Set-PatScheduledJob -ServiceId $Service.Id -Id $job.Id -Owner $Owner -AuthenticationContext $context -ErrorAction Continue
               if(-not $ret)
               {
                   $errorCount=$errorCount+1
                   Write-Host "update failed. Server Id: $($Service.Id) Job id: $($job.id)  and Owner: $Owner " -ForegroundColor Red
               }
            }
        }

        if($errorCount -le 0)
        {
           Write-Host "Step2: update jobs owner successfully" -ForegroundColor Green
        }else
        {
           Write-Host "Step2: update some jobs owner but the count : $errorCount ones failed" -ForegroundColor Red    
        }            
            
    } catch
    {
        Write-Host "Error: steps encounter errors:$($_.Exception.Message)" -ForegroundColor Red
    }
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

Update-JobOwners