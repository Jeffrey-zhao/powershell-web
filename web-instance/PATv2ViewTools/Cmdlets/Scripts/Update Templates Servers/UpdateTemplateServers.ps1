<#    
    IMPORTANT: YOU NEED TO RUN THE POWERSHELL PROMPT AS ADMINISTRATOR IN ORDER TO UPDATE TEMPLaTES WITH 'SERVERS' PAREMETER    
               you first need import some related dll files
    .DESCRIPTION
        The important steps for this function
            1. Get script auth config
            2. Get all templates by calling api
            3. Filter and convert templates with servers then get required templates
               and save these filtered templates in current path with timestap name
            4. Update required templates by calling api
    
    .EXAMPLE
        1.update filter templates with paramerter "ServerPath"
        .\UpdateTemplateServers.ps1 -ServerPath ".\Servers.txt" -ServiceId 2019 -DistributionUnitId 2093
        2.update templates with parameter "Servers" 
        .\UpdateTemplateServers.ps1 -Servers @("server1","server2")  -ServiceId 2019    
#>

[CmdletBinding()]
Param(
    #The needed Update Servers saved in file(eg. Severs.txt)
    # per server per line
    [Parameter(mandatory=$true,ParameterSetName="ServerPath")]
    [String] $ServerPath,

    #The needed update Servers in cmd line (eg.@("server1","server2"))
    #
    [Parameter(mandatory=$true,ParameterSetName="Servers")]
    [string[]] $Servers,

    #The Servic eId
    [Parameter(mandatory=$true)]
    [String] $ServiceId,

    #The Distribution Unit Id
    [Parameter(mandatory=$false)]
    [String] $DistributionUnitId
)

Function UpdateTemplates
{
    try
    {
        if(![string]::IsNullOrEmpty($ServerPath))
        {
            $Servers=[string[]](Get-Content -Path $ServerPath)
        }
    }catch
    {
        Write-Host "try to get servers from ($serversPath) but errors occur" -ForegroundColor Red
        return
    }

    try
    {
        #1. get all templates
        Write-Host "Step1: start calling api to get all templates" -ForegroundColor Green
        $templates = Get-PatTemplates -ServiceId $ServiceId -DistributionUnitId $DistributionUnitId -AuthenticationContext $context
        Write-Host "Step1: get templates successfully" -ForegroundColor Green

        #2. filter templates and convert templates,Save converted templates
        Write-Host "Step2: start to filter templates and convert them" -ForegroundColor Green
        $filteredTemplates=@()
        foreach($template in $templates)
        {
           foreach($serverlist in $template.ServerLists)
           {
               if([string]::IsNullOrEmpty($serverlist.Servers))
               {
                   continue
               }
               $filteredServers=[string[]]([System.linq.Enumerable]::Except([string[]]$serverlist.Servers,[string[]]$Servers))
               if($filteredServers.count -lt $serverlist.Servers.count)
               {
                   $serverlist.Servers=$filteredServers
                   $serverlist.InsertedDate=[datetime]::UtcNow
                   $serverlist.InsertedBy=$User
                   $flag=$true
               }
           }
           if($flag)
           {
                $filteredTemplates+=$template
                $flag=$false
           }
        }

        #save filter templates for user checking
        if($filteredTemplates.count -le 0)
        {
            Write-Host "Step2: the count of templates is 0,and not update any )" -ForegroundColor Yellow    
            return
        }else
        {
            $filteredTemplates > "NeedToUpdateTemplates_$(Get-Date -Format "yyyyMMddHHmmss").txt"
            Write-Host "Step2: filter and convert templates are successful.the count of Filter templates is:[$($filteredTemplates.count)] " -ForegroundColor Green
        }

        #3. update filtered templates
        Write-Host "Step3: start to update templates" -ForegroundColor Green
        $errorCount=0
        foreach($template in $filteredTemplates)
        {
           $returnTemplate=Set-PatTemplate -ServiceId $ServiceId -Template $template -AuthenticationContext $context
		   if([string]::IsNullOrEmpty($returnTemplate))
           {
                $errorCount=$errorCount+1
                Write-Host "update failed. Server Id: $($ServiceId) and template id: $($template.Id) " -ForegroundColor Red
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

UpdateTemplates