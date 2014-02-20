import android
import re
import sqlite3

fp = open("/sdcard/PSR Entries.txt", 'r+')
fp.write("Text from python")

/*
droid = android.Android()
psrDate = droid.getIntent().result['%SMSRD']
psrTime = droid.getIntent().result['%SMSRT']
psrSender = droid.getIntent().result['%SMSRF']
psrText = droid.getIntent().result['%SMSRB']
*/

fp.write("From python psrDate = %s" % psrDate)
fp.write("From python psrTime = %s" % psrTime)
fp.write("From python psrSender = %s" % psrSender)
fp.write("From python psrText = %s" % psrText)
fp.close()

/*
result = re.search('RaffleID is (\w*).', psrText)
if result is not None:
    psrEntry = result.groups()[0]

    conn = sqlite3.connect('/sdcard/MyRec/MyRec.db')
    cur = conn.cursor()
    cur.execute("Insert into PSR([date], [time], sender, msg) values "\
            "(psrDate, psrTime, psrSender, psrEntry)")
    conn.close()
*/
