#----------------------------------------------------------------------------------------------------------------- 
# File: PAT.LogManager.psm1 
# 
# namespace: PAT.LogManager 
#
# Target: 
#       1) Manage log file.
# 
# How to use: 
#       Construct Logger use LogManagerConstructor and we can use the in global variable
#       Destruct Logger when we never use them
#       Configure-Logger will set up Logger to use
#       Logger-Debug will display message and logging message as debug information use Logger
#       Logger-Info will display message and logging message as an information use Logger
#       Logger-Warn will display message and logging message as warn information use Logger
#       Logger-Error will display message and logging message as error information use Logger
#       Logger-Fatal will display message and logging message as fatal error information use Logger
#
# Sample: Import-Module .\LogManager.ps1; LogManagerConstructor; Configure-Logger C:\log\log4net.dll C:\Test.config C:\log\log.txt 'PowerShell';
# invoke Sample1: $Global:Logger['PowerShell'].Info();
# invoke Sample2: Logger-Info 'PowerShell' "Test Info";
#----------------------------------------------------------------------------------------------------------------- 
Function LogManagerConstructor(){
	$Global:Logger = @{};
}

Function LogManagerDestructor(){
	Clear-Variable 'Logger' -Scope Global;
}

Function ConfigureLogger($Log4netDll,$ConfigFile,$Logfile,$LoggerName){
	if(!$Global:Logger){
		LogManagerConstructor;
	}
	[system.reflection.assembly]::LoadFile($Log4netDll) | Out-Null;
	$Config = new-object System.IO.FileInfo($ConfigFile);
	if([log4net.GlobalContext]::Properties["LogFolder"] -ne $Logfile)
	{
		Write-Host "add $Logfile"
		[log4net.GlobalContext]::Properties["LogFolder"]=$Logfile;
		[log4net.Config.XmlConfigurator]::Configure($Config);
	}
	$Global:Logger[$LoggerName] =  [log4net.LogManager]::GetLogger($LoggerName);
}

Function LoggerDebug($LoggerName, $Message)
{
	write-host "$(Get-Date) [Debug][$LoggerName]: $Message" -ForegroundColor Magenta;
	if($Global:Logger[$LoggerName]){
		$Global:Logger[$LoggerName].Debug($Message);
	}else{
		write-host "Not find Logger $LoggerName to logging debug message: $Message" -ForegroundColor Yellow;
	}
}

Function LoggerPassed($LoggerName, $Message)
{
	write-host "$(Get-Date) [Info][$LoggerName]: $Message" -ForegroundColor Green;
	if($Global:Logger[$LoggerName]){
		$Global:Logger[$LoggerName].Info($Message);
	}else{
		write-host "Not find Logger $LoggerName to logging info message: $Message" -ForegroundColor Red;
	}
}

Function LoggerFailed($LoggerName, $Message)
{
	write-host "$(Get-Date) [Info][$LoggerName]: $Message" -ForegroundColor Red;
	if($Global:Logger[$LoggerName]){
		$Global:Logger[$LoggerName].Error($Message);
	}else{
		write-host "Not find Logger $LoggerName to logging info message: $Message" -ForegroundColor Red;
	}
}

Function LoggerInfo($LoggerName, $Message)
{
	write-host "$(Get-Date) [Info][$LoggerName]: $Message";
	if($Global:Logger[$LoggerName]){
		$Global:Logger[$LoggerName].Info($Message);
	}else{
		write-host "Not find Logger $LoggerName to logging info message: $Message" -ForegroundColor Yellow;
	}
}

Function LoggerWarn($LoggerName, $Message)
{
	write-host "$(Get-Date) [Warn][$LoggerName]: $Message" -ForegroundColor Yellow;
	if($Global:Logger[$LoggerName]){
		$Global:Logger[$LoggerName].Warn($Message);
	}else{
		write-host "Not find Logger $LoggerName to logging warn message: $Message" -ForegroundColor Yellow;
	}
}

Function LoggerError($LoggerName, $Message)
{
	write-host "$(Get-Date) [Error][$LoggerName]: $Message" -ForegroundColor Red;
	if($Global:Logger[$LoggerName]){
		$Global:Logger[$LoggerName].Error($Message);
	}else{
		write-host "Not find Logger $LoggerName to logging error message: $Message" -ForegroundColor Yellow;
	}
}

Function LoggerFatal($LoggerName, $Message)
{
	write-host "$(Get-Date) [Fatal][$LoggerName]: $Message" -ForegroundColor DarkRed;
	if($Global:Logger[$LoggerName]){
		$Global:Logger[$LoggerName].Fatal($Message);
	}else{
		write-host "Not find Logger $LoggerName to logging fatal message: $Message" -ForegroundColor Yellow;
	}
}