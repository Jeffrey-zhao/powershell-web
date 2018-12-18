<#
.EXAMPLE
#jobIds.txt
28270
28265
28269

$context=.\SetupEnvironment.ps1 int
Import-Module .\Generate-DependentJobsJson.ps1 -Force
Generate-DependentJobsJson -ServiceName Corpnet -JobIdsPath .\jobIds.txt
Generate-DependentJobsJson -ServiceName Corpnet -JobBulkJsonFile .\JobBulkRecords\test_08.json
#>
function Generate-DependentJobsJson {
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $true,
            ParameterSetName = "JobBulk")]
        [string] $JobBulkJsonFile,   

        #input one JobId per line
        [Parameter(mandatory = $true,
            ParameterSetName = "JobIds")]
        [String] $JobIdsPath,

        [Parameter(mandatory = $false)]
        [String] $OutputFile,
		
		[Parameter(mandatory = $false)]
		[ValidateSet('dist','src')]
        [String] $ReplaceDataPath='dist'
    )

    $Services = Get-AvailablePatServices -AuthenticationContext $context
    $Service = ($Services |Where-Object {$_.Name -eq $ServiceName})

    if ($null -eq $Service -or $Service -eq '') {
        Write-Warning "please input a valid Service Name"
        return $null
    }
    else {
        $ServiceId = $Service.Id
    }

    $script:data = @()
    $script:links = @()
    $script:JobIdSet = @()

    $getDataAndLinksScript = {
        param([string] $JobId)
        try
        {
        $item = $script:data |? {$_.id -eq $JobId -and $null -ne $_.start_date}
        if ($null -ne $item) {
            return $item.start_date
        }

        $job = Get-PatJob -ServiceId $ServiceId -JobId $JobId -AuthenticationContext $context
        if ($null -eq $job) {return $null}
        $script:data += @{id = [string]$job.Id; start_date = $job.ScheduledDatetime; duration = 1; text = $job.Name; type = "task"; open = $true; 
			custom=@{status = [string]$job.JobStateInfo.State;jobids=''} 
		}    
        $dependentJobIds = @()
        if ($null -ne $job.DependentJobs) {   
            $dependentJobIds += $job.DependentJobs.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
        }
        if ($dependentJobIds.count -gt 0) {
            $date=@()
            foreach ($dependentJobId in $dependentJobIds) {
                $script:links += @{id = 0; source = $dependentJobId; target = $JobId; type = 0;}
                $date += Invoke-Command -ScriptBlock $getDataAndLinksScript -ArgumentList $dependentJobId                                 
            }  
            if ($null -eq $date -and $date.count -lt 0) {
                Write-Warning "please check your supported file,can not search Job id :$($JobId)"
                throw
            }
            else {   
                $ret=($date |Measure-Object -Minimum ).Minimum
                if($ret -eq $null -or $ret -eq 0)
                {
                    $ret=[datetime]::UtcNow
                }
                ($script:data |? {$_.id -eq $job.Id}).start_date = $ret.AddDays(2)
                return $ret
            }   
        }        
        return $job.ScheduledDatetime
    }catch{
        Write-Error $_
    }
}
    add-type -assembly system.web.extensions
    $ps_js = new-object system.web.script.serialization.javascriptSerializer

    switch ($PSCmdlet.ParameterSetName) {
        "JobBulk" { 
            $json = Get-Content $JobBulkJsonFile      
            $jobBulk = $ps_js.DeserializeObject($json)            
            $script:JobIdSet += $jobBulk.Values.JobId.where( {$_ -ne $null})
            break
       
        }
        "JobIds" {
            $fileOrigin = Get-Content $JobIdsPath          
            
            foreach ($line in $fileOrigin) {
                if (![string]::IsNullOrEmpty($line)) {
                    $script:JobIdSet += $line.Trim()
                }
            } 
            break                           
        }
    }

    foreach ($jobId in $script:JobIdSet) {
        $ret = Invoke-Command -ScriptBlock $getDataAndLinksScript -ArgumentList $jobId 
    }

    #format start_date
    $linkId = 0
    foreach ($link in $script:links) {
        $linkId++
        $link.id = $linkId
    }

    foreach ($item in $script:data) {
        $item.start_date = $item.start_date.ToString("yyyy-MM-dd HH:mm:ss")
        $script:links |%{ if($_.source -eq $item.id) {$item.custom.jobids +=$_.target+','}}
        $item.custom.jobids=$item.custom.jobids.trim(',')
    }

    $obj = @{data = $script:data; links = $script:links}

    $recordsFolder = ".\DependentJobsFolders"

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
	$jsonContent=$ps_js.Serialize($obj)
    $jsonContent |Out-File -FilePath $OutputFile
	$jsonContent |Out-File -FilePath ".\PATV2ViewTools\$ReplaceDataPath\data\job.json"
    Write-Host "Generate json file in path '$($OutputFile)'successfully ..." -ForegroundColor Green
}

