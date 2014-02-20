#Script INSERT for given table
param
(
	[string]$server='localhost',
	[string]$database='orihrm_docomo',
	[string]$table='employee_biodata',
	[string]$output_file='C:\scripts\orihrm_docomo_biodata.sql'
)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

$svr = new-object("Microsoft.SqlServer.Management.SMO.Server") $server
$scripter = new-object("Microsoft.SqlServer.Management.SMO.Scripter")($server)

#Get the database and table objects
$db = $svr.Databases[$database]
$tbl = $db.tables | where {$_.name -eq $table}

#Set scripter options to ensure only data is scripted
$scripter.Options.ScriptSchema = $false
$scripter.Options.ScriptData = $true

#Exclude GO after every line
$scripter.Options.NoCommandTerminator = $true

if($output_file -ne "")
{
	$scripter.Options.FileName = $output_file
	$scripter.Options.ToFileOnly = $true
}

#Output the script
foreach($s in $scripter.EnumScript($tbl))
{
	write-host $s
}

