<#
.SYNOPSIS

Performs monthly data updates.

.DESCRIPTION

The Update-Month.ps1 script updates the registry with new data generated
during the past month and generates a report.

.PARAMETER InputPath
Specifies the path to the CSV-based input file.

.PARAMETER OutputPath
Specifies the name and path for the CSV-based output file. By default,
MonthlyUpdates.ps1 generates a name from the date and time it runs, and
saves the output in the local directory.

.INPUTS

None. You cannot pipe objects to Update-Month.ps1.

.OUTPUTS

None. Update-Month.ps1 does not generate any output.

.EXAMPLE

C:\PS> .\Update-Month.ps1

.EXAMPLE

C:\PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv

.EXAMPLE

C:\PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv -outputPath `
C:\Reports\2009\January.csv
#>


function Get-Data { 
    <#
        .SYNOPSIS

        Adds a file name extension to a supplied name.

        .DESCRIPTION

        Adds a file name extension to a supplied name.
        Takes any strings for the file name or extension.

        .PARAMETER Name
        Specifies the file name.

        .PARAMETER Extension
        Specifies the extension. "Txt" is the default.

        .INPUTS

        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS

        System.String. Add-Extension returns a string with the extension
        or file name.

        .EXAMPLE

        C:\PS> extension -name "File"
        File.txt

        .EXAMPLE

        C:\PS> extension -name "File" -extension "doc"
        File.doc

        .EXAMPLE

        C:\PS> extension "File" "doc"
        File.doc

        .LINK

        http://www.fabrikam.com/extension.html

        .LINK

        Set-Item
        #>
    param (
        [string]$InputPath, 
        [string]$OutPutPath
    )
}