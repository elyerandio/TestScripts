param
(
	[string]$ServerName=$env:COMPUTERNAME,
	[Parameter(Mandatory=$true)] [string]$DatabaseName,
	[Parameter(Mandatory=$true)] [string]$tableName,
	[Parameter(Mandatory=$true)] [string]$outfile
)
invoke-sqlcmd -ServerInstance $ServerName -Database $DatabaseName -Query "SELECT * FROM $tableName" | export-csv -NoTypeInfo -path ./$outfile.csv 
