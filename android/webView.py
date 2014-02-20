import android

droid = android.Android()
droid.webViewShow('file:///sdcard/sl4a/scripts/MyScripts/webView.html', None)
while True:
    result = droid.waitForEvent('say').result
    if result:
        droid.ttsSpeak(result['data'])
