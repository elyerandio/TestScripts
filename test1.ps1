[int]$a = read-host -prompt "Enter a number please "
[int]$b = read-host -prompt "Enter a second number "
$c = read-host "Select any one of the following operator - + / * "

switch($c)
{
	'+' { $a + $b }
	'-' { $a - $b }
	'*' { $a * $b }
	'/' { $a / $b }
	default { write-host 'Wrong arithmetic operation' $a $c $b }
}
