param
(
	[string]$SQLServer
)

$SqlConnection = new-object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=$SQLServer;Database=master;Integrated Security=True"
$SqlCmd = new-object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "Select @@version as SQLServerVersion"
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = new-object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = new-object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$SqlConnection.Close()
$DataSet.Tables[0]
