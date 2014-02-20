#requires -version 2.0   
Param ( 
	[parameter(Mandatory = $true)]  
	[string] $SrcServer, 
	[parameter(Mandatory = $true)]  
	[string] $SrcDatabase, 
	[parameter(Mandatory = $true)]  
	[string] $SrcTable, 
	[parameter(Mandatory = $true)]  
	[string] $DestServer, 
	[string] $DestDatabase, # Name of the destination database is optional. When omitted, it is set to the source database name. 
	[string] $DestTable, # Name of the destination table is optional. When omitted, it is set to the source table name.  
	[switch] $Truncate # Include this switch to truncate the destination table before the copy. 
) 

Function ConnectionString([string] $ServerName, [string] $DbName)  
{ 
	"Data Source=$ServerName;Initial Catalog=$DbName;Integrated Security=True;" 
} 


########## Main body ############  
If ($DestDatabase.Length -eq 0) 
{ 
	$DestDatabase = $SrcDatabase 
} 

If ($DestTable.Length -eq 0) 
{ 
	$DestTable = $SrcTable 
} 

If ($Truncate) 
{  
	$TruncateSql = "TRUNCATE TABLE " + $DestTable 
	Sqlcmd -S $DestServer -d $DestDatabase -Q $TruncateSql 
} 
 
$SrcConnStr = ConnectionString $SrcServer $SrcDatabase 
$SrcConn  = New-Object System.Data.SqlClient.SQLConnection($SrcConnStr) 
$CmdText = "SELECT * FROM " + $SrcTable 
$SqlCommand = New-Object system.Data.SqlClient.SqlCommand($CmdText, $SrcConn)   
$SrcConn.Open() 
[System.Data.SqlClient.SqlDataReader] $SqlReader = $SqlCommand.ExecuteReader() 
 
Try 
{ 
	$DestConnStr = ConnectionString $DestServer $DestDatabase 
	$bulkCopy = New-Object Data.SqlClient.SqlBulkCopy($DestConnStr, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity) 
	$bulkCopy.DestinationTableName = $DestTable 
	$bulkCopy.WriteToServer($sqlReader) 
} 

Catch [System.Exception] 
{ 
	$ex = $_.Exception 
	Write-Host $ex.Message 
}
 
Finally 
{ 
	Write-Host "Table $SrcTable in $SrcDatabase database on $SrcServer has been copied to table $DestTable in $DestDatabase database on $DestServer" 
	$SqlReader.close() 
	$SrcConn.Close() 
	$SrcConn.Dispose() 
	$bulkCopy.Close() 
} 

