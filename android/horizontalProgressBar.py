import android
import time

droid = android.Android()
droid.dialogCreateHorizontalProgress('My Progress', 'Wait', 50)
droid.dialogShow()
for i in range(51):
    droid.dialogSetCurrentProgress(i)
    time.sleep(0.1)
droid.dialogDismiss()
