param
(
	[string]$infile,
	[int]$last
)

$readBuffer = get-content $infile | select-object -last $last
#[datetime]$mydate

foreach($record in $readBuffer)
{
	#write-host $record

	if($record -match "^\d\d\d\d-\d\d-\d\d")
	{
		$mydate = $record.substring(0, 22)
		write-host $mydate -foregroundcolor White -backgroundcolor Blue
	}
}
