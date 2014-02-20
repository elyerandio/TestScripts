import android

droid = android.Android()
res = droid.smsGetMessageCount(True).result

msg = "You have " + str(res) + " unread messages"
droid.makeToast(msg)
