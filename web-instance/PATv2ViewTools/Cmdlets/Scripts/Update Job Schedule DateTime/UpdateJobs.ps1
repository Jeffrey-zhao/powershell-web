<#    
    IMPORTANT: YOU NEED TO RUN THE POWERSHELL PROMPT AS ADMINISTRATOR IN ORDER TO UPDATE JOBS
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
            1. Get all related jobs
            2. convert and update jobs 
    
    .EXAMPLE
        1.update jobs with JobIds
         .\UpdateJobs.ps1 -ServiceName 'CORPNET-KEZ2' -JobIds @('24726','24727') -PostponeDays 7 
        2.update jobs from File
         .\UpdateJobs.ps1 -ServiceName 'CORPNET-KEZ2' -FromFile '.\JobsFile.csv'
#>

[CmdletBinding()]
    Param(

        #The needed Update Service Name
        # per server per line
        [Parameter(mandatory=$true)]
        [String] $ServiceName,

        #The needed update job ids 
        [Parameter(mandatory=$true,ParameterSetName='JobIds')]
        [String[]] $JobIds,       

        #The job needed to postpone days 
        [Parameter(mandatory=$true,ParameterSetName='JobIds')]
        [int] $PostponeDays,

        #The needed update Jobs from a file(it is *.csv file with two columns title:'JobId','ScheduledDateTime')
        [Parameter(mandatory=$true,ParameterSetName='File')]
        [string] $FromFile
    )
    
Function Update-Jobs
{   
    try
    {        
        #1. get all related jobs
        $Services=get-AvailablePatServices -AuthenticationContext $context
        $Service=$Services |Where-Object{$_.Name -eq $ServiceName}
        $jobs=@()
        $filterJobs=@()      
        $now=[datetime]::UtcNow

        Write-Host "Step1: start calling api to get related jobs and convert them." -ForegroundColor Green
        if($JobIds -ne $null)
        {
            foreach($jobId in $JobIds)
            {
                $jobs += Get-PatJob -ServiceId $Service.Id -JobId $jobId -AuthenticationContext $context
            }

            # exclude not schedule jobs
            foreach($job in $jobs)
            { 
                if($job.ScheduledDateTime -ge $now)
                {
                    $job.ScheduledDateTime=$job.ScheduledDateTime.AddDays($PostponeDays)
                    $filterJobs+=$job
                }
            }
        }
        elseif($FromFile -ne $null)
        {
            $jobs=Import-Csv $FromFile 
            foreach($job in $jobs)
            {
                $tempJob = Get-PatJob -ServiceId $Service.Id -JobId $job.JobId -AuthenticationContext $context
                if($tempJob.ScheduledDateTime -ge $now)
                {
                   $tempJob.ScheduledDateTime=$Job.ScheduledDateTime
                   $filterJobs+=$tempJob
                }
            }
        }
        else
        {
            Write-Host "No support right parameters,please check your parameters"
        }

        Write-Host "Step1: get  and convert jobs successfully and the count of jobs is : $($filterJobs.count)" -ForegroundColor Green
        
        #2. update jobs
        Write-Host "Step2: start to update jobs" -ForegroundColor Green               
        #save filter jobs for user checking
        if($filterJobs.count -le 0)
        {
            Write-Host "Step2: the count of filterJobs is 0,and not update any" -ForegroundColor Yellow    
            return
        }

        $errorCount=0

        foreach($job in $filterJobs)
        {
            $ret=Set-PatScheduledJob -ServiceId $Service.Id -Id $job.Id -ScheduledDateTime $Job.ScheduledDateTime  -AuthenticationContext $context -ErrorAction Continue
            if(-not $ret)
           {
               $errorCount=$errorCount+1
               Write-Host "update failed. Server Id: $($Service.Id) Job id: $($job.id)" -ForegroundColor Red
           }
        }

        if($errorCount -le 0)
        {
           Write-Host "Step2: update jobs successfully" -ForegroundColor Green
        }else
        {
           Write-Host "Step2: update jobs but the count :$errorCount ones failed" -ForegroundColor Red    
        }      
       
            
    } catch
    {
        Write-Host "Error: steps encounter errors:$($_.Exception.Message)" -ForegroundColor Red
    }
}
  
Update-Jobs