import android

droid = android.Android()

title = 'Alert'
message = ('This alert box has 3 buttons '
           'and waits for you to press one.')
droid.dialogCreateAlert(title,message)
droid.dialogSetPositiveButtonText('Yes')
droid.dialogSetNegativeButtonText('No')
droid.dialogSetNeutralButtonText('Cancel')
droid.dialogShow()
response = droid.dialogGetResponse().result

print response['which']
