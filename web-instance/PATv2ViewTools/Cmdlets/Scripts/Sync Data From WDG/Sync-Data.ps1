<#
.example
  #normal update
  .\Sync-Data.ps1 -Environment "int"
  .\Sync-Data.ps1 -Environment "prod"
#>

[CmdletBinding()]
Param(    
    #The environment(ie. int, prod) in which the script runs, default is 'int'.
    [String] $Environment
)

#get data from ConnectionString by executing CommandText
function Execute-SelectSql
{
    param(
        [parameter(mandatory=$true)]
        [string]$CommandText,
        [parameter(mandatory=$true)]
        [string]$ConnectionString,
        [parameter(mandatory=$true)]
        [string]$loggerName
    )
    try{
        $SQLConnection = New-Object System.Data.SQLClient.SQLConnection
        if($ConnectionString -ne $null -or $ConnectionString -ne '')
        {
            $SQLConnection.ConnectionString =$ConnectionString;
        }else
        {
            LoggerInfo $loggerName "connection string is null or empty";
            exit
        }
        if($SqlConnection -ne $null -or $SqlConnection -ne "")
        {
           $SqlConnection.Open()
        }

        $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
        $SQLCommand.Connection = $SQLConnection
        $SQLCommand.CommandText = $CommandText

        $SQLAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SQLCommand                 
        $SQLDataSet = New-Object System.Data.DataSet
        $SqlAdapter.fill($SQLDataSet) | out-null

        $SQLDataSet.Tables[0]|Select-Object  * -ExcludeProperty ItemArray,HasErrors,RowError,RowState,Table
    }
    catch{
        LoggerError $loggerName $_
        
    }finally{
        $SQLAdapter.Dispose()
        $SQLCommand.Dispose()
        $SqlConnection.Close()
    }
}

#transform data 
function Transform-Data
{
    param(
        [array]$WDGServers,
        [string]$loggerName
    )
    if($WDGServers -ne $null)
    {
        LoggerInfo $loggerName 'WDGServerList is not empty and return entities.'
        # reorganize data
        $group=$WDGServers |Group-Object Name
        $MissingKBInfo=@()
        foreach($obj in $group)
        {
            $MissingKBs=@()
            if([System.String]::IsNullOrEmpty($obj.Group.LatestScanDate))
            {
                $latestScanDate=$null
            }else
            {
                $latestScanDate=$obj.Group.LatestScanDate[0]
            }
            for($i=0;$i-lt $obj.Count;$i++)
            {
                if(-not [System.String]::IsNullOrEmpty($obj.Group[$i].KB_Title) -or -not [System.String]::IsNullOrEmpty($obj.Group[$i].PatchSource))
                {
                  $MissingKBs+=@{KBTitle=$obj.Group[$i].KB_Title;PatchSource=$obj.Group[$i].PatchSource}
                }
            }
            $MissingKBInfo+=[PSCustomObject]@{Name=$obj.Name;MissingKBList=@{MissingKBs=$MissingKBs};LatestScanDate=$latestScanDate}
 
        }
        $MissingKBInfo
    }else
    {
        LoggerInfo $loggerName 'WDGServerList is null and return empty.' 
        $null      
    }
}

#merge two array objects
function Merge-Data
{
       param(
        [array]$TransformData,
        [array]$PatServers,
        [string]$loggerName
    ) 

    if(-not [string]::IsNullOrEmpty($TransformData) -and -not [string]::IsNullOrEmpty($PatServers))
    {
        LoggerInfo $loggerName "Merge-Data return Merged entities."
        Join-Object -Left $PatServers -Right $TransformData -LeftJoinProperty ChangedName -RightJoinProperty Name  -Type AllInLeft `
        -LeftProperties Id,JobId,Name,StartTime,EndTime `
        -RightProperties @{name='PropertiesJson';expression={$_.MissingKBList|ConvertTo-Json -Depth 3 -Compress}},`
        @{name='LatestScanDate';expression={If ([System.String]::IsNullOrEmpty($_.LatestScanDate)) {$null} Else {$_.LatestScanDate}}}
         
     }
     elseif([string]::IsNullOrEmpty($TransformData)  -and -not [string]::IsNullOrEmpty($PatServers))
     {
        LoggerInfo $loggerName "Merge-Data return UnMerged entities."
        $PatServers |select Id,JobId,Name,StartTime,EndTime,PropertiesJson,LatestScanDate
     }
     else
     {
        LoggerInfo $loggerName "Merge-Data return empty."
        $null
     }
}

#compare data whether current update date is different from last sync data.
function Compare-Data
{
    param(
        [array]$CurrentUpdateData,
        [string]$UpdatePath,
        [string]$loggerName
    )

    if($CurrentUpdateData -ne $null)
    {              
        if( -not (Test-Path $UpdatePath))
        {
           New-Item -ItemType file -Force -Path $UpdatePath | out-null
        }

        $lastUpdateData=Import-Csv $UpdatePath
        if([System.String]::IsNullOrEmpty($lastUpdateData))
        {
            LoggerInfo $loggerName "last update data is empty but will return origin update data"
            $CurrentUpdateData
        }
        else
        {   
            #get diff from last updated servers with a server's name and latestScanDate
            $Servers=Compare-Object $CurrentUpdateData $lastUpdateData -Property Name,LatestScanDate|Where-Object{$_.SideIndicator -eq "<="}|Group-Object Name |select Name
            #Write-Host "need to update servers:$($servers.Name)" -ForegroundColor Yellow
            LoggerInfo $loggerName "last update data is not empty and will return compare update data"
            $CurrentUpdateData | Where-Object {$_.Name -in $servers.Name}
        }
    }
    else
    {
        LoggerInfo $loggerName "return current update data is null and will return null "
        $null
    }      
}

# sync no-updated servers with servers' name and last server id 
function get-Servers
{
 param(
    [parameter(mandatory=$true)]
    [object] $context,
    [parameter(mandatory=$false)]
    [string] $ServerId,
    [parameter(mandatory=$false)]
    [string[]] $Names,
    [string] $loggerName
    )

    $TotalServers=@()
    LoggerInfo $loggerName ' Get Servers from pat db ...'
    $servers= Get-PatPatchingServer -AuthenticationContext $context -LastServerId $ServerId -Names $Names
    while ($true)
    {
        $TotalServers+=$servers
        $lastId = $servers[-1].Id
        $servers = Get-PatPatchingServer -LastServerId $lastId -AuthenticationContext $context -Names $Names
        if ($servers.Count -le 0)
        {
                break
        }
    }   
    return $TotalServers
}

# get nearest timestap from specific file
function get-SpecificFile
{
    param(
        [parameter(mandatory=$true)]
        [string] $Path,
        [bool] $IsNearesttimestamp=$true,
        [string] $Filter='*'
    )
    
    if($IsNearesttimestamp)
    {
        $File=Get-ChildItem -Path $path |Where-Object {$_.Name -like $Filter} |Sort-Object CreationTime -Descending |Select-Object -First 1
    }else
    {
        $File=Get-ChildItem -Path $path |Where-Object {$_.Name -like $Filter} |Sort-Object CreationTime |Select-Object -First 1        
    } 
    $File
}

#test path exist or not,if no ,create it
function New-SpecificItem
{
    param(
        [string] $ItemType,
        [string] $Path,
        [string] $loggerName,
        [bool] $IsThrowError=$false
    )
    if(-not (test-path $Path))
    {        
        LoggerInfo $loggerName "$Path does not exist,and will create the file/directory..."
        if(-not $IsThrowError)
        {
            New-Item -ItemType $ItemType -Force -Path $Path |out-null
        }else
        {
            throw "$Path does not exist..."
        }
    }
}
#calc start time
$startTime=get-date

$path=Split-Path -Parent $MyInvocation.MyCommand.Path

ipmo $path\Join-Object.ps1 -Force
ipmo $path\LogManager.psm1 -Force

#Start up log manager
$log4net = "$path\log4net.dll"
$configFile = "$path\App.config"
$logfile = "$path\Log\log.txt"
$loggerName = "PowerShell"
ConfigureLogger $log4net $configFile $logfile $loggerName;

# set int or prod parameters
# $Environment="prod"

#############################################################
#step 1 --set/get file (updatefile.csv and PatScriptConfig.config)
#############################################################

#set or get last/current file path and get config file
LoggerInfo $loggerName '--- Enter Step 1 ---'
LoggerInfo $loggerName '--- Enter Get/Set Initial Variable  ---'

#create UpdateFiles
New-SpecificItem -ItemType "Directory" -Path "$path\UpdateFiles" -LoggerName $loggerName
#create NoUpdateFiles
New-SpecificItem -ItemType "Directory" -Path "$path\NoUpdateFiles" -LoggerName $loggerName

$filePath=get-SpecificFile -Path "$path\UpdateFiles" -Filter '*.csv'

#if file exists,then get file name and set saved file name 
$startTimeFormat=$startTime.ToString("yyyyMMddHHmmss")
if($filePath -ne $null)
{
    if([datetime]::ParseExact($filePath.Name.Split('.')[0],"yyyyMMddHHmmss",$null) -lt ($startTime))
    {
        $lastUpdatePath=$filePath.FullName
        $SavePath="$FilePath.DirectoryName\$startTimeFormat.csv"
    }  
}
else
{
    #if this file not exists ,then create it and set save file path to UpdateFile+(dateTime).csv
    $lastUpdatePath="$path\UpdateFiles\$startTimeFormat.csv"
    $SavePath=$lastUpdatePath
}

#get last synced server Id
$lastServerId=$null 
New-SpecificItem -ItemType "File" -Path "$path\LastServerId.csv" -LoggerName $loggerName
$lastServers=Import-Csv -Path "$path\LastServerId.csv"
if($lastServers -ne $null)
{
    $lastServerId=$lastServers[-1].LastServerId
}

LoggerInfo $loggerName '--- Exit Get/Set Initial Variable ---'
LoggerInfo $loggerName '--- Exit Step 1  ---'

#############################################################
#step 2 --get all servers from pat db
#############################################################

LoggerInfo $loggerName '--- Enter Step 2 ---'
LoggerInfo $loggerName '--- Enter Get pat data  ---'

$TotalPATServers=@()
$NeedToUpdateServers=@()
$NeedToSaveServers=@()

#get servers from last not update servers 
$updatePath=get-SpecificFile -Path "$path\NoUpdateFiles" -Filter "*.csv"
$PatServersFromFile=@()
if(![string]::IsNullOrEmpty($updatePath.FullName))
{
    $PatServersFromFile+=import-csv -Path $updatePath.FullName |Sort-Object Id
    $ServerNames=$PatServersFromFile |select Name -Unique
    if(![string]::IsNullOrEmpty($lastServerId) -and ![string]::IsNullOrEmpty($PatServersFromFile))
    {
        $Id=$PatServersFromFile[0].Id
        $ServerId=if([int]::parse($lastServerId) -gt $id) {$id}
    }
}
if($ServerNames -ne $null)
{
    $querysize=20
    for($i=0;$i -lt $ServerNames.count;$i +=$querysize)
    {
        $TotalPATServers+= get-Servers -context $context -ServerId $ServerId -Names $ServerNames[$i..($i+$querysize-1)].Name -loggerName $loggerName
    }
}
# get servers from pat db
$TotalPATServers+= get-Servers -context $context -ServerId $lastServerId -loggerName $loggerName
#filter servers
$NeedToUpdateServers+=$TotalPATServers|Where-Object {-not [System.String]::IsNullOrEmpty($_.StartTime) -and -not [System.String]::IsNullOrEmpty($_.EndTime)} |Sort-Object Id
$NeedToSaveServers+=$TotalPATServers|Where-Object {[System.String]::IsNullOrEmpty($_.StartTime) -or [System.String]::IsNullOrEmpty($_.EndTime)}
#save last synced server id into a file
if($NeedToUpdateServers -ne $null)
{
    $MaxServerId=($NeedToUpdateServers |Sort-Object Id)[-1].Id
    [PsCustomObject]@{LastServerId=$MaxServerId;CurrentTime=$startTimeFormat} |Export-Csv -Path "$path\LastServerId.csv" -Append -NoTypeInformation
}

#$NeedToUpdateServers
LoggerInfo $loggerName '--- Exit get pat data ---'
LoggerInfo $loggerName '--- Exit Step 2  ---'
##############################################################
#step 3 -- get wdg data from db by pat servers' names
##############################################################
LoggerInfo $loggerName '--- Enter Step 3 ---'
LoggerInfo $loggerName '--- Enter get wdg data  ---'
#split All servers' name into chunks of names
$ServerList=@()
$ServerList+=$NeedToUpdateServers|Group-Object Name |Select Name

$serverGroup=@()
#set size of servers per query
$querySize=20
for ($i = 0; $i -lt $ServerList.Length; $i += $querySize) {
    $serverGroup+=[PSCustomObject]@{Servers=(($ServerList[$i..($i+$querySize-1)].Name) -join ",")}
}

# set connection string and sql command text
$ConnectionString="server=AZPATV2RPT01;database=PATV2_Reporting;Integrated Security=True;"
$CommandString=@"
    select a.Name,a.LatestScanDate,b.KB_Title,b.PatchSource 
                from [WDG].[Insight_Scan_Asset] a 
                left join [WDG].[Insight_Scan_Result] b
                on a.Name=b.Netbios
                and b.PatchSource in ('InCycle','OutCycle') 

"@

#All servers info by pat servers' name
$WDGServerList=@()
# Query DB with group Names command text to get data from wdg
foreach($group in $serverGroup)
{
    #handler server name with domain
    #for example :change 'server1.farest.com' to 'server1'
    $ChangedGroup=$group.Servers.Split(',') |
    %{
        if($_.IndexOf('.') -lt 0) 
        {
            $index=$_.length
        } 
        else 
        {
            $index=$_.IndexOf('.')
        }
        $_.Substring(0,$index)
    }
    $CondtionNames="'$($changedGroup -join "','")'"
    $CommandText="$CommandString Where a.Name in ($($CondtionNames))"
    #get data from wdg
    $WDGServers=@()
    $WDGServers=Execute-SelectSQL -CommandText $CommandText -ConnectionString $ConnectionString -loggerName $loggerName
    $WDGServerList+=$WDGServers
}
#$WDGServerList
LoggerInfo $loggerName '--- Exit get wdg data ---'
LoggerInfo $loggerName '--- Exit Step 3  ---'
#################################################################################
#         -- compare data with last updated data from csv file.
# step 4  -- transform to according data
#         -- merge PropertiesJson and LatestScanData to needed update servers
#################################################################################

LoggerInfo $loggerName '--- Enter Step 4  ---'

#compare two kinds of data for current update data and last syncing data.
LoggerInfo $loggerName "---Enter Compare-Data---" 
$CompareServers=@()
$CompareServers+=Compare-Data -CurrentUpdateData $WDGServerList -UpdatePath $lastUpdatePath  -loggerName $loggerName
#$CompareServers 
LoggerInfo $loggerName "---Exit compare-Data---" 

#transform data to according format
LoggerInfo $loggerName "---Enter Transform-Data---" 
$TransformServers=@()
$TransformServers+=Transform-Data -WDGServers $CompareServers -loggerName $loggerName
#$TransformServers 
LoggerInfo $loggerName "---Exit Transform-Data---"

#ConvertedPatServerList
$ConvertedPatServerList=@()
$ConvertedPatServerList+=$NeedToUpdateServers |select @{name="ChangedName";expression={$_.Name.split('.')[0]}},*

#merge data 
LoggerInfo $loggerName "---Enter Merge-Data---" 
$UpdateServers=@()
$UpdateServers=Merge-Data -TransformData $TransformServers -PatServers $ConvertedPatServerList -loggerName $loggerName
LoggerInfo $loggerName "---Exit Merge-Data---" 

#remove servers with latestScanDate is empty or null
$ToUpdateServers=@()
$ToUpdateServers+=$UpdateServers |Where {-not [System.String]::IsNullOrEmpty($_.LatestScanDate)}

#save not find missing kbs servers into files
$NeedToSaveServers+=$UpdateServers |Where {[System.String]::IsNullOrEmpty($_.LatestScanDate)}

LoggerInfo $loggerName '--- Exit Step 4 ---'
#################################################################################
#step 5 -- update pat server using  group way and save updated servers into csv file.
#################################################################################
LoggerInfo $loggerName '--- Enter Step 5 ---'
LoggerInfo $loggerName '--- Enter Update pat data ---'

$updates=@()
$groupSize=20
for($i=0;$i -lt $toUpdateServers.Length;$i+=$groupSize)
{
    $updates+=@{Servers=[Microsoft.UniversalStore.ComIamDev.SecureGenericWorkExecutionFramework.UI.DTO.PatPatchingServer[]]($toUpdateServers|Select -Skip $i -First $groupSize)}
}
$updatedCount=0
foreach($update in $updates)
{
    try
    {
        #$result=Set-PatchingServersProperty -PatchingServers $update.Servers -AuthenticationContext $context -ToFile "d:\output.json"
        $result=Set-PatchingServersProperty -PatchingServers $update.Servers -AuthenticationContext $context
        #after compared ,save current update date into a new file like 'UpdateFiles_yyyyMMddHHmmss.csv'.
        $names=$update.Servers.Name |%{$_.Split('.')[0]} |Get-Unique
        #if prod or int,remove this clause below and replace it with 'if()...'
        #$CompareServers|Where-Object {$_.Name -in $names} |Export-Csv $SavePath -Append -NoTypeInformation
        if($result -ne $null)
        {
            $updatedCount+=20
            $CompareServers|Where-Object {$_.Name -in $names}|Export-Csv $SavePath -Append -NoTypeInformation
        }
    }
    catch
    {
        LoggerError $loggerName "there is an error:($_)" 
    }
}
#if update failed ,then save no updated servers
$NeedToSaveServers+=$updates.Servers |select Id,Name,JobId,StartTime,EndTime,PropertiesJson,LatestScanDate -Skip $updatedCount
if(![string]::IsNullOrEmpty($NeedToSaveServers))
{
    $NeedToSaveServers|Sort-Object Id| Export-Csv -Path "$path\NoUpdateFiles\$startTimeFormat.csv" -Append -NoTypeInformation
}

LoggerInfo $loggerName '--- Exit Update pat data ---' 
LoggerInfo $loggerName '--- Exit Step 5 ---'

#calc end time
$endTime=get-date
$consumeTime=$endtime-$startTime
LoggerDebug $loggerName "run this script...updated data rows:$($updatedCount) `nstartime is at ($startTime) `nend time is at ($endTime), `nso total consume time is ($consumeTime)"
