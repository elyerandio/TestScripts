import android
import webbrowser

droid = android.Android()
code = droid.scanBarcode()
url = code[1]['extras']['SCAN_RESULT']
droid.makeToast("The url scanned is " + url)
droid.notify('Scan result',url)
droid.dialogCreateAlert('Scan Result', url)
droid.dialogSetPositiveButtonText('Open in browser')
droid.dialogSetNegativeButtonText('Exit')
droid.dialogShow()
response = droid.dialogGetResponse().result
droid.dialogDismiss()
if response.has_key('which'):
    result = response['which']
    if result == 'positive':
        droid.startActivity('android.intent.action.VIEW', url)
        #webbrowser.open(url)

#url = "http://books.google.com?q=%d" % isbn
#droid.startActivity('android.intent.action.VIEW', url)
