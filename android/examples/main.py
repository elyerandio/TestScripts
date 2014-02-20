from android import Android
import time

droid = Android()
droid.webViewShow('file:///sdcard/sl4a/scripts/Examples/index.html',True)

time.sleep(5)
