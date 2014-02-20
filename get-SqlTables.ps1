param
(
	[string]$SQLServer,
	[string]$Database
)

$SqlConnection = new-object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True"

$SqlCmd = new-object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "Select name from sysobjects where type = N'U'"
$SqlCmd.Connection = $SqlConnection

$SqlAdapter = new-object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd

$DataSet = new-object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$DataSet.tables[0] | sort-object name
$SqlConnnection.Close()
