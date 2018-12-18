@echo off

set ScriptEnv=prod
set inputEnv=""
set /P inputEnv=Please input environment(Options: "int", "onebox", "prod". If not set, "prod" is used):
if /I "%inputEnv%" == "int" set ScriptEnv=int
if /I "%inputEnv%" == "onebox" set ScriptEnv=onebox

set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"

echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
echo sLinkFile = "%USERPROFILE%\Desktop\PatScript_%ScriptEnv%.lnk" >> %SCRIPT%
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
echo oLink.TargetPath = "powershell.exe" >> %SCRIPT%
set CurrentDir=%~dp0
echo oLink.Arguments = "-noprofile -command &{ start-process powershell -ArgumentList '-noexit -noprofile -file %CurrentDir%Scripts\SetupEnvironment.ps1 %ScriptEnv% %CurrentDir%' -verb RunAs}" >> %SCRIPT%
echo oLink.Save >> %SCRIPT%
cscript /nologo %SCRIPT%
del /f %SCRIPT%
goto :EOF

:tolower 
for %%L IN (a b c d e f g h i j k l m n o p q r s t u v w x y z) DO SET %1=!%1:%%L=%%L! 
goto :EOF