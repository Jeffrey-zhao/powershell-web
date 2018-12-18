<#	
	IMPORTANT: YOU NEED TO RUN THE POWERSHELL PROMPT AS ADMINISTRATOR IN ORDER TO SAVE DATA TO DB	

	.PREREQUISITE
		1.Need install the MSRC api module first.
			1. Download the src file from https://github.com/Microsoft/MSRC-Microsoft-Security-Updates-API and unzip it to a folder(e.g C:\temp\)
			2. Run PowerShell prompt as administrator and run the following command:
				import-module C:\temp\MSRC-Microsoft-Security-Updates-API-master\src\MsrcSecurityUpdates
			3. Run following command to ensure it installed successfully
				get-command -module MsrcSecurityUpdates
		2.Also need the following files in the folder of this script if you want to Query DB/SAVE data to DB.
			1.PatScriptConfig.xml
			2.PAT api dlls
				log4net.dll
				Microsoft.IdentityModel.Clients.ActiveDirectory.dll
				Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll
				Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.Common.dll
				Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.UI.dll
				Microsoft.UniversalStore.IamDev.Common.dll
				Microsoft.UniversalStore.IamDev.HttpClient.Common.dll
				Newtonsoft.Json.dll
				System.Net.Http.Formatting.dll
													
    .EXAMPLE
		1.Get updates from MSRC(not access to PAT DB)
		.\PopulateTableSecurityUpdates.ps1 -ID "2018-JUL"
       	   
		2.Get updates from MSRC and querying existing security update info from PAT DB
		.\PopulateTableSecurityUpdates.ps1 -ID "2018-JUL" -QueryDB:$true
		
		3.Get updates from MSRC and save to PAT DB
        .\PopulateTableSecurityUpdates.ps1 -ID "2018-JUL" -Save:$true -PatchCycle "2018-7-10" 
#>


[CmdletBinding()]
Param(

	#Get security update for the specified CVRF ID (format: yyyy-MMM, ie. 2017-Nov)
	[String] $ID,
	
	#The flag(ie. $true/$false) indicates querying security update summary info or not, default is false.
	[Switch] $QueryDB = $false,
	
	#The flag(ie. $true/$false) indicates saving the security updates to DB or not, default is false.
	[Switch] $Save = $false,
	
	#The specified patch cycle date(format: yyyy-MM-dd, ie. 2017-11-14) used to save to DB
	[String] $PatchCycle	
)

Function Test-IsLocalAdministrator {
    $identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal( $identity )
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

Function WriteHttpError
{
	param(
		[parameter(mandatory=$true)]
        [PSObject]$HttpError
	)
	
	Write-Error "HTTP requset failed with error: $($HttpError.Exception)"
	if($HttpError.Exception.Response){
		$result = $HttpError.Exception.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($result)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();	
		Write-Host -ForegroundColor YELLOW "Response body: $($responseBody)"	
	}
} 

#this command need put outside of function or will get error.
$currentFolder = (split-path -parent $MyInvocation.MyCommand.Definition)

Function GetSecurityUpdatesByMSRCApi{
	$patApiModule = "Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.UI"
	$patApiModulePath = "$($currentFolder)\$($patApiModule).dll"	
	
	#parameter check	
	if($Save -and (-not (Test-IsLocalAdministrator))){
		Throw "Please run the Powershell prompt as Administrator."
	}
	
	if(-not $ID){
		Throw "You need to specify the value for -ID(ie.2017-Nov)"
	}

	if ($Save){
		if(-not $PatchCycle){
			Throw "You need to specify the value for -PatchCycle(ie. 2017-11-14 for 2017 Nov) in order to save entries."
		}
		
		if(-not (Get-Date -date $PatchCycle)){
			Throw "Value of -PatchCycle is invalid."
		}
	}
	
	if ($Save -or $QueryDB){		
		Write-Host -ForegroundColor GREEN "Checking if PAT api module imported..."
		if(Get-Command -module $patApiModule){
			Write-Host -ForegroundColor GREEN "PAT api module found."
		}else{			
			try{
				Write-Host -ForegroundColor GREEN "Importing PAT api module $($patApiModulePath)..."
				ipmo $patApiModulePath
				
				if(Get-Command -module $patApiModule){
					Write-Host -ForegroundColor GREEN "Import completed."
				}else{
					Write-Warning "Failed to import module, going to stop. Please ensure the file($($patApiModulePath)) exist in the same folder as this script."
					return;
				}						
			}catch{
				Write-Error "Failed to import module due to $($_.Exception)."
				return;
			}
		}
	}	
	

	#1.setup
	Write-Host -ForegroundColor GREEN "Check if MSRC module imported..."
	if(Get-Command -module MsrcSecurityUpdates){
		Write-Host -ForegroundColor GREEN "MSRC module found."
	}else{
		Throw "Please import MsrcSecurityUpdates module first, you can get it from https://github.com/Microsoft/MSRC-Microsoft-Security-Updates-API"
	}
	
	Write-Host -ForegroundColor GREEN "Setup access token..."	
	if($global:MSRCAdalAccessToken) {
		Write-Host -ForegroundColor GREEN "Access token found."
	} else{	
		set-MSRCAdalAccessToken
		if($global:MSRCAdalAccessToken){
			Write-Host -ForegroundColor GREEN "Access token created."
		}else{
			Throw "Failed to setup access token for MSRC API."
		}
	}
	
	#2.call MSRC api		
	Write-Host -ForegroundColor GREEN "Calling MSRC API..."
	$softwaresAndKBs = Get-MsrcCvrfDocument -ID $ID | Get-MsrcCvrfAffectedSoftware
	Write-Host -ForegroundColor GREEN "Call MSRC API completed."
	if($Save -and (!$softwaresAndKBs -or $softwaresAndKBs.count -eq 0)){
		Write-Host -ForegroundColor YELLOW "No data returned from MSRC API, please re-open the PowerShell prompt and try again."
		return;
	}
	
	#3.re-organize data	
	#remove updates that are superseded by others first
	$supersededKBs = @{}
	$softwaresAndKBs | where-Object { ($_.Supercedence -is [array] -and  $_.Supercedence.count -gt 0) -or $_.Supercedence} | %{ 
		$item = $_
		$item.Supercedence | where-Object { $_ -match '^\d+$' } | %{ $supersededKBs[$_ + "_" + $item.FullProductName] = $true }
	}
	
	$hash = @{}
	$softwaresAndKBs | %{ 
		$software = $_
		$found = ($software.KBArticle | where-Object { $supersededKBs[($_.ID + "_" + $software.FullProductName)] })
		if(!$found -or $found.count -eq 0){
			$software.KBArticle | where-Object { $_.ID -match '^\d+$' } | %{ $hash[$software.FullProductName] += @($_.ID) }
		}
	}

	$uniqueHash = @{}
	$hash.GetEnumerator() | %{ $uniqueHash[$_.key] = @($_.value | sort -unique )}
	
	$kbTypes = @{}
	$softwaresAndKBs | %{ 
		$software = $_
		$software.KBArticle | %{ $kbTypes[$software.FullProductName + $_.ID] = $_.SubType } 
	}
	
	$kbList = $uniqueHash.GetEnumerator() | %{
		$kvp = $_		
		[PSCustomObject]@{
			FullProductName = $_.key;
			KBs = $_.value | %{ 
				[PSCustomObject]@{
					ID = "KB"+$_;
					SubType = $kbTypes[$kvp.key + $_];
				}								
			}
		}
	}
		
	$mappedList = $kbList | %{		
		[PSCustomObject]@{			
			PatchCycle = $PatchCycle;		
			FullProductName = $_.FullProductName;			
			MonthlyRollupKB = $(($_.KBs | where-Object {$_.SubType -eq "Monthly Rollup"}).ID);			
			IndividualKBs = ($_.KBs | where-Object {$_.SubType -ne "Monthly Rollup" -and $_.SubType -ne "Alternate Cumulative"} | %{"$($_.ID)"}) -join ',';			
			AlternateKBs = ($_.KBs | where-Object {$_.SubType -eq "Alternate Cumulative"} | %{"$($_.ID)"}) -join ',';
		}
	}
		
	#for test
	#$uniqueHash | out-gridview
	#$kbTypes | out-gridview
	#ConvertTo-Json $mappedList
	#$mappedList | out-gridview
	Write-Host -ForegroundColor GREEN $("Group data completed, " +$mappedList.length + " entries found.")
	
	#4. save to DB
	if($QueryDB -or $Save){ 		 
		Write-Host -ForegroundColor GREEN "Checking ADFS auth context..."
		if($context){
			Write-Host -ForegroundColor GREEN "Auth context found."
        }else{
			Write-Error "Failed to find ADFS auth context, going to exit."
            return;
        }
	}
	
	if (-not $Save){	
		if($QueryDB){
			try{
				Write-Host -ForegroundColor GREEN "Querying summary info of table security updates..."
				$r = Get-SecurityUpdateSummary -AuthenticationContext $context				
				Write-Host -ForegroundColor YELLOW "The querying API returned: $($r)" 										
			}catch{
				WriteHttpError($_);
				return;
			}	
		}
	
		Write-Host -ForegroundColor GREEN $("You choose not to save to DB.")
		$kbList | out-gridview
		$mappedList | out-gridview
		$softwaresAndKBs | out-gridview
		$supersededKBs | out-gridview
		return;
	}
		
	try{
		Write-Host -ForegroundColor GREEN "Querying summary info of table security updates..."
		$r = Get-SecurityUpdateSummary -AuthenticationContext $context		 
		Write-Host -ForegroundColor YELLOW "The querying API returned: $($r)" 
			
		if($r -and (Get-Date -date $PatchCycle) -eq (Get-Date -date $r.LatestPatchCycle) -and ($r.RowCountOfLatestCycle -gt 0)){
			try{
				Write-Host -ForegroundColor GREEN "Going to delete existing $($r.RowCountOfLatestCycle) rows of patch cycle $($PatchCycle) from DB..."
				$r = Remove-SecurityUpdates -AuthenticationContext $context -PatchCycle $PatchCycle					 
				Write-Host -ForegroundColor GREEN "The deleting API returned(# of deleted rows): $($r)"					 
			}catch{
				WriteHttpError($_)
				return;
			}
		}					 
	}catch{
		WriteHttpError($_);
		return;
	}						 
	
	try{		
		Write-Host -ForegroundColor GREEN "Calling saving security updates api..."		
		$r = Add-SecurityUpdates -AuthenticationContext $context -Entries $mappedList
		if ($r) {
			Write-Host -ForegroundColor GREEN "The saving API returned: $($r)" 
		} else {				
			Write-Warning "No truthy result returned from the saving API."
		}			
	}catch{					
		WriteHttpError($_);
		return;
	}

	try{
		Write-Host -ForegroundColor GREEN "Querying summary info of table security updates after saving..."
		$r = Get-SecurityUpdateSummary -AuthenticationContext $context		
		Write-Host -ForegroundColor YELLOW "The querying API returned: $($r)" 		
	}catch{
		WriteHttpError($_);
		return;
	}		
}

GetSecurityUpdatesByMSRCApi $ID $QueryDB $Save $PatchCycle