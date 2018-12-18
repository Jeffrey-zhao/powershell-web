function Manage-DependentJobs
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string]
        $JobBulkJsonFile,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkCancel",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkPatchOptions",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkFixedTime",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkRelativeTime",
                   ValueFromPipelineByPropertyName=$false)]
        [string]
        $BulkGuid,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobCancel",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobPatchOptions",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobFixedTime",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobRelativeTime",
                   ValueFromPipelineByPropertyName=$false)]
        [int[]]
        $JobIds,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkCancel",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobCancel",
                   ValueFromPipelineByPropertyName=$false)]
        [switch]
        $Cancel,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkPatchOptions",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobPatchOptions",
                   ValueFromPipelineByPropertyName=$false)]
        [hashtable]
        $PatchOptions,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkFixedTime",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobFixedTime",
                   ValueFromPipelineByPropertyName=$false)]
        [datetime]
        $FixedTime,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetBulkRelativeTime",
                   ValueFromPipelineByPropertyName=$false)]
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SetJobRelativeTime",
                   ValueFromPipelineByPropertyName=$false)]
        [int]
        $RelativeTimeMins
    )

    $script:jobsToManage = @()

    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    $json = Get-Content $JobBulkJsonFile
    $jobBulk = $ps_js.DeserializeObject($json)

    switch -wildcard ($PsCmdlet.ParameterSetName)
    {
        {($_ -eq "SetBulkFixedTime") -or ($_ -eq "SetBulkRelativeTime")} 
        {

            $jobs = $jobBulk[$BulkGuid]

            $scriptBlockCheckRootJob = 
            {
                param([PSObject]$jobObject)

                foreach($dependentJob in $jobObject.DependentJobs)
                {
                    $checkResult = Invoke-Command $scriptBlockCheckRootJob -ArgumentList $dependentJob

                    if(($checkResult["SelfPostponed"] -eq $true) -or ($checkResult["AncestorPostponed"]) -eq $true)
                    {
                        return @{"SelfPostponed" = $false
                                 "AncestorPostponed" = $true}
                    }
                }

                $job = Get-PatJob -ServiceId $jobObject.ServiceId -JobId $jobObject.JobId -AuthenticationContext $context

                if(($job.JobStateInfo.State -ne [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Pending) -and ($job.JobStateInfo.State -ne [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::New))
                {
                    return @{"SelfPostponed" = $false
                             "AncestorPostponed" = $false}
                }
                else
                {
                    $jobInserted = $false

                    foreach($tmpJob in $script:jobsToManage)
                    {
                        if($tmpJob.JobId -eq $jobObject.JobId)
                        {
                            $jobInserted = $true
                            break
                        }
                    }

                    if(!$jobInserted)
                    {
                        $script:jobsToManage += $jobObject
                    }
                    return @{"SelfPostponed" = $true
                             "AncestorPostponed" = $false}
                }
            }

            foreach($job in $jobs)
            {
                $result = Invoke-Command $scriptBlockCheckRootJob -ArgumentList $job
            }
        }

        "SetJob*" {
            $jobCollection = $jobBulk.Values | ForEach-Object {foreach($job in $_) {$job}}
            foreach($jobObject in $jobCollection)
            {
                if($jobObject.JobId -in $JobIds)
                {
                    $job = Get-PatJob -ServiceId $jobObject.ServiceId -JobId $jobObject.JobId -AuthenticationContext $context
                    if(($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Pending) -or ($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::New))
                    {
                        $jobInserted = $false

                        foreach($tmpJob in $script:jobsToManage)
                        {
                            if($tmpJob.JobId -eq $jobObject.JobId)
                            {
                                $jobInserted = $true
                                break
                            }
                        }

                        if(!$jobInserted)
                        {
                            $script:jobsToManage += $jobObject
                        }
                    }
                }
            }
        }

        Default
        {
            foreach($jobObject in $jobBulk[$BulkGuid])
            {
                $job = Get-PatJob -ServiceId $jobObject.ServiceId -JobId $jobObject.JobId -AuthenticationContext $context
                if(($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Pending) -or ($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::New))
                {
                    $jobInserted = $false

                    foreach($tmpJob in $script:jobsToManage)
                    {
                        if($tmpJob.JobId -eq $jobObject.JobId)
                        {
                            $jobInserted = $true
                            break
                        }
                    }

                    if(!$jobInserted)
                    {
                        $script:jobsToManage += $jobObject
                    }
                }
            }
        }
    }

    switch -wildcard ($PsCmdlet.ParameterSetName)
    {
        "*FixedTime" 
        {
            foreach($jobToPostpone in $script:jobsToManage)
            {
                $job = Get-PatJob -ServiceId $jobToPostpone.ServiceId -JobId $jobToPostpone.JobId -AuthenticationContext $context
                if(($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Pending) -or ($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::New))
                {
                    $result = Set-PatScheduledJob -ServiceId $jobToPostpone.ServiceId -Id $jobToPostpone.JobId -ScheduledDateTime $FixedTime -AuthenticationContext $context
                    if(!$result)
                    {
                        Write-Output $result
                    }
                }
            }
        }

        "*RelativeTime" 
        {
            foreach($jobToPostpone in $script:jobsToManage)
            {
                $job = Get-PatJob -ServiceId $jobToPostpone.ServiceId -JobId $jobToPostpone.JobId -AuthenticationContext $context
                if(($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Pending) -or ($job.JobStateInfo.State -eq [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::New))
                {
                    if($job.ScheduledDateTime -ne $null)
                    {
                        $newScheduledDateTime = ([DateTime]($job.ScheduledDateTime)).AddMinutes($RelativeTimeMins)
                        $result = Set-PatScheduledJob -ServiceId $jobToPostpone.ServiceId -Id $jobToPostpone.JobId -ScheduledDateTime $newScheduledDateTime -AuthenticationContext $context
                        if(!$result)
                        {
                            Write-Output $result
                        }
                    }
                    else
                    {
                        $newRelativeTimeMins = $RelativeTimeMins
                        if($job.RelativeTimeInMinutes -ne $null)
                        {
                            $newRelativeTimeMins += $job.RelativeTimeInMinutes
                        }

                        $result = Set-PatScheduledJob -ServiceId $jobToPostpone.ServiceId -Id $jobToPostpone.JobId -RelativeTimeMins $newRelativeTimeMins -AuthenticationContext $context
                        if(!$result)
                        {
                            Write-Output $result
                        }
                    }
                }
            }
        }

        "*Cancel"
        {
            $jobsNotCanceled = @()

            foreach($jobObject in $script:jobsToManage)
            {
                $job = Get-PatJob -ServiceId $jobObject.ServiceId -JobId $jobObject.JobId -AuthenticationContext $context
                if(($job.JobStateInfo.State -ne [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Pending) -and ($job.JobStateInfo.State -ne [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::New))
                {
                    $jobsNotCanceled += $jobObject.JobId
                }
                else
                {
                    $result = Set-PatJobState -ServiceId $jobObject.ServiceId -Id $jobObject.JobId -AuthenticationContext $context -State ([Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Cancelled)
                    if(!$result)
                    {
                        Write-Output $result
                    }
                }

                if(($jobsNotCanceled -ne $null) -and ($jobsNotCanceled.Count -gt 0))
                {
                    Write-Output "The following jobs are not canceled:"
                    Write-Output $jobsNotCanceled
                }
            }
        }

        "*PatchOptions"
        {
            $PatchOptionsJson = [string]::Empty

            if(($PatchOptions -ne $null) -and ($PatchOptions.Count -gt 0))
            {
                try
                {
                    $optionArray = @()
                    $PatchOptions.Keys | % {$optionArray += @{Key = $_
                                                              Value=$PatchOptions.Item($_)}}
                    $PatchOptionsJson = ConvertTo-Json $optionArray
                }
                catch
                {
                    Write-Warning "Failed to generate patch options"
                    Write-Warning $_
                }

                if([string]::IsNullOrEmpty($PatchOptionsJson))
                {
                    Write-Output "PatchOptions is empty, no jobs are modified"
                    Return
                }
            }

            foreach($jobObject in $script:jobsToManage)
            {
                $job = Get-PatJob -ServiceId $jobObject.ServiceId -JobId $jobObject.JobId -AuthenticationContext $context
                if(($job.JobStateInfo.State -ne [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::Pending) -and ($job.JobStateInfo.State -ne [Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.PatJobStatus]::New))
                {
                    $jobsNotValid += $jobObject.JobId
                }
                else
                {
                        
                    $result = Set-PatScheduledJob -ServiceId $jobObject.ServiceId -Id $jobObject.JobId -PatchOptions $PatchOptionsJson -AuthenticationContext $context
                    if(!$result)
                    {
                        Write-Output $result
                    }
                }

                if(($jobsNotValid -ne $null) -and ($jobsNotValid.Count -gt 0))
                {
                    Write-Output "The following jobs' PatchOptions are not modified:"
                    Write-Output $jobsNotValid
                }
            }
        }

        Default {}
    }
}