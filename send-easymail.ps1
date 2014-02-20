function Send-EasyMail([string] $subject, [string] $body)
{
	#Setup some basic info
	$from = new-object System.Net.Mail.MailAddress("rbimosv@gmail.com")
	$to = new-object System.Net.Mail.MailAddress("elyerandio@yahoo.com")
	$SMTPServer = "smtp@gmail.com"

	# Create the email object
	$emailMsg = new-object System.Net.Mail.MailMessage($from, $to)
	$emailMsg.subject = $subject
	$emailMsg.Body = $body

	#$SMTPClient = new-object System.Net.Mail.SmtpClient($SMTPServer, 587)
	$SMTPClient = new-object System.Net.Mail.SmtpClient
	$SMTPClient.host = 'smtp@gmail.com"
	
	# Enable SSL protocol 
	#$SMTPClient.EnableSsl = $True

	# Create credential object we'll use to authenticate ourselves to the SMTP Server
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("rbimosv","@Bimosin")

	# Send the email
	$SMTPClient.Send($emailMsg)
}

# Test the function
Send-EasyMail -subject 'Test Subject' -body 'This is the message from Powershell script'
