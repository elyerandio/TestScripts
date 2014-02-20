param
(
	[int]$a = $(Throw "Please provide Number as first parameter"),
	[string]$c,
	[int]$b,
	[switch]$help
)

if($help)
{
	write-host "Usage : $a + $b"
}
else
{
	write-host "First parameter is" $a
	write-host "Second parameter is" $c
	write-host "Third parameter is" $b
}
