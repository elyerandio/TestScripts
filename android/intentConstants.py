import android

droid = android.Android()
myconst = droid.getConstants('android.content.Intent').result
const_list = []
for c in myconst:
    mystr = "%s = [%s]" % (c, myconst[c])
    const_list.append(mystr)

droid.dialogCreateAlert('Available Intent Constants')
droid.dialogSetItems(const_list)
droid.dialogShow()

