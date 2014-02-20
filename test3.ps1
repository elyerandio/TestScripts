param
(
	[int]$multiplyNumber,
	[int]$startRange,
	[int]$endRange
)

write-host "Multiplication table of " $multiplyNumber
for ($num = $startRange; $num -le $endRange; $num++)
{
	$result = $multiplyNumber * $num
	write-host $multiplyNumber ' x ' $num ' = ' $result
}
