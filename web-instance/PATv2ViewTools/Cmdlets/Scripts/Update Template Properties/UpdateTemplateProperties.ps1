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
			1. Get all templates by calling api
			2. Filter templates with condition then get required template
            3. Update required template by calling api

    .EXAMPLE
		1.update templates
		.\UpdateTemplateProperties.ps1 -ServiceName 'CORPNET-KEZ2' -TemplateNames @("ServerReadinessCheck_PAT-DU-Test","ServerReadinessCheck_CORPNET-DU2","ServerReadinessCheck_CPPATV2DUFE01") -PatchingCompletionRate '0.12' -PatchingTimeout '480'
#>

[CmdletBinding()]
Param(
	#The needed Update Service Id
    # per server per line
    [Parameter(mandatory=$true)]
	[String] $ServiceName,

    #The needed update Template Name
    [Parameter(mandatory=$true)]
	[String[]] $TemplateNames,

    #The needed update PatchingCompletionRate
    [Parameter(mandatory=$false)]
	[string] $PatchingCompletionRate,

	#The needed update Timeout
    [Parameter(mandatory=$false)]
	[string] $PatchingTimeout
)

Function Update-TemplateProperties
{   
	try
	{   
        #1. get all templates
        Write-Host "Step1: start calling api to get all templates" -ForegroundColor Green
        $Services=get-AvailablePatServices -AuthenticationContext $context
        $Service=$Services |Where-Object{$_.Name -eq $ServiceName}

        $templates = Get-PatTemplates -ServiceId $Service.Id  -AuthenticationContext $context
        Write-Host "Step1: get templates successfully" -ForegroundColor Green
        
        #2. filter templates
        Write-Host "Step2: start to filter templates" -ForegroundColor Green
        $filteredTemplates=@()
        foreach($template in $templates)       
        {	
            if($template.Name -in $TemplateNames)
            {
                if([string]::IsNullOrEmpty($template.Properties))
                {
                    # compatible with pervious version data
                    #it will initialize Properties to default value
                    $template.Properties=[PsCustomObject]@{PatchingCompletionRate=1.0;PatchingTimeout=480}
                }
				if(![string]::IsNullOrEmpty($PatchingCompletionRate))
				{
					$template.Properties.PatchingCompletionRate=$PatchingCompletionRate 
				}
				if(![string]::IsNullOrEmpty($PatchingTimeout))
				{
					$template.Properties.PatchingTimeout=$PatchingTimeout
				}                              
                $filteredTemplates+=$template
            }
        }

        if($filteredTemplates.count -le 0)
        {
            Write-Host "Step2: the count of templates is 0,and not update any " -ForegroundColor Yellow    
            return
        }else
        {
            Write-Host "Step2: filter templates successfully. the count of Filter templates is:$($filteredTemplates.count) " -ForegroundColor Green
        }
        #3. update filtered templates
        Write-Host "Step3: start to update templates" -ForegroundColor Green
        $errorCount=0
        $filteredTemplates
        foreach($template in $filteredTemplates)
        {
           $returnTemplate=Set-PatTemplate -ServiceId $Service.Id -Template $template -AuthenticationContext $context -ErrorAction Continue
           if([string]::IsNullOrEmpty($returnTemplate))
           {
                $errorCount=$errorCount+1
                Write-Host "update failed. Server Id: $($Service.Id) Job id: $($job.id)  and Owner: $Owner " -ForegroundColor Red
           }
        }

        if($errorCount -le 0)
        {
           Write-Host "Step3: update templates successfully" -ForegroundColor Green
        }else
        {
           Write-Host "Step3: update templates but the count :$errorCount ones failed " -ForegroundColor Red    
        }   
          
	} catch
	{
		Write-Host "Error: steps encounter errors:$($_.Exception.Message)" -ForegroundColor Red
	}
}
	
Update-TemplateProperties