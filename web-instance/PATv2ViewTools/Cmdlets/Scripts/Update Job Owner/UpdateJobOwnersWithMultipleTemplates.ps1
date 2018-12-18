<#    
    .IMPORTANT: YOU NEED TO RUN THE POWERSHELL PROMPT AS ADMINISTRATOR IN ORDER TO UPDATE JOB WITH PAREMETER    
    .DESCRIPTION
        The important steps for this function
            1. Get Skw config
            2. Get all jobs in patch cycle by calling api
            3. change and save jobs with owner 
    
    .EXAMPLE
        1.update filter jobs
         .\UpdateJobOwnersWithMultipleTemplates.ps1 -ServiceName 'CORPNET-KEZ2' -Owner 'test@microsoft.com'  -TemplateNames @('Test2-Checking-win2016&DU','Sample_Checking_Purpose_PATv2_Test') -PatchCycle '07/2018' 
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
    [string[]] $TemplateNames,

    #The needed update PatchCycle format 'MM/yyyy' (ie.'05/2015')
    #available breaks "/"
    [ValidatePattern("^(0[1-9]|1[012])/(\d{4})$")]
    [Parameter(mandatory=$true)]
    [String] $PatchCycle,

    [Parameter(mandatory=$false)]
    [ValidateSet("Scheduled")]
    [string] $JobType="Scheduled"
)

Function Update-JobOwnersWithMultipleTemplates
{   
    try
    {   
        $count=0
        foreach($templateName in $TemplateNames)
        {
            $count=$count+1
            Write-Host "update the count: $count with template: $templateName" -ForegroundColor Yellow
            .\UpdateJobOwners.ps1 -ServiceName $ServiceName -Owner $Owner  -TemplateName $templateName -PatchCycle $PatchCycle
            
        }         
    } catch
    {
        Write-Host "Error: steps encounter errors:$($_.Exception.Message)" -Debug -ForegroundColor Red
    }
}

Update-JobOwnersWithMultipleTemplates