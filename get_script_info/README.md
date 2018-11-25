# how to get info from script
1. $scripts=get-childItem ./execute_powershell_script -Filter *.ps1
2. $Import-Module ./execute_powershell_script/test.ps1
3. $functions=$scripts[0] |Find-Function
3. $members=get-help $scripts[0].Name |get-member
4. $properties=get-command $scripts[0].Name |get-member --> anc get parameter default value