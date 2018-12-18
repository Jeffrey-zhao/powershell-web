[cmdletbinding()]
param(
    [parameter(Mandatory = $true)]
    [string] $Arg
)
write-host $Arg
$context=@{Name='Test1';pp=$Arg}