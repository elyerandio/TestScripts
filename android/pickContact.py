import android
import pprint

droid = android.Android()
contact = droid.pickContact().result
if contact == None:
    print "Nothing selected"
else:
    data = droid.queryContent(contact['data']).result
    msg = []
    for key in data[0]:
        msg.append("%-20s = %s" % (key, data[0][key]))

    pprint.pprint(msg)
    droid.dialogCreateAlert('Contact Detail','Contact Detail')
    droid.dialogSetItems(msg)
    droid.dialogShow()
