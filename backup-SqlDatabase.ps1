param
(
	[string]$SqlServer,
	[string]$Database,
	[string]$Location,
	[string]$BackupType
)

$SQL = 'master.dbo.uspBackupDB'
write-host $SQL

$conn = new-object System.Data.SqlClient.SqlConnection("Data Source=$SqlServer;Initial Catalog=master; Integrated Security=SSPI")
$cmd = new-object System.Data.SqlClient.SqlCommand("$SQL", $conn)
$cmd.CommandType = [System.Data.CommandType]'StoredProcedure'
$cmd.Parameters.Add("@databasename",[System.Data.SqlDbType] "Varchar", 128) | out-null
$cmd.Parameters.Add("@Folderpath", [System.Data.SqlDbType] "Varchar", 1000) | out-null
$cmd.Parameters.Add("@BackupType", [System.Data.SqlDbType] "Varchar", 4) | out-null
$cmd.Parameters["@databasename"].Value = $Database
$cmd.Parameters["@Folderpath"].Value = $Location
$cmd.Parameters['@BackupType"].Value = $BackupType
$conn.open()
$cmd.ExecuteNonQuery() | out-null
$conn.Close()
