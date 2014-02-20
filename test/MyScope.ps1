#$myvar=1
write-host "Myvar defined as $myvar"

function myfunction
{
	write-host "Myvar inside the myfunction is $myvar"
	write-host "Upgrading myvar inside the myfunction..."
	$myvar=2
	write-host "Value of myvar after being updated inside myfunction is $myvar"
}

write-host "Calling myfunction"
myfunction

write-host "Value of myvar after calling the myfunction is $myvar"
