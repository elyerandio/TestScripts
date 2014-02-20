param
(
[int]$a,
[int]$b,
$c
)

switch($c)
{
	'+' { $a + $b }
	'-' { $a - $b }
	'*' { $a * $b }
	'/' { $a / $b }
	default { write-host 'Wrong arithmetic operation' $a $c $b }
}
