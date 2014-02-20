import android
import sqlite3
import datetime

droid = android.Android()
textFrom = droid.getIntent().result['%SMSRF']
textName = droid.getIntent().result['%SMSRN']
textBody = droid.getIntent().result['%SMSRB']
textDate = datetime.date.isoformat()
textTime = droid.getIntent().result['%SMSRT']

conn = sqlite3.connect('/sdcard/MyRec/MyRec.db')
cur = conn.cursor()
cur.execute("Insert into TextMessages([date], [time],inout, sender, sender_name, msg) values " \
            "(textDate, textTime, 'in', textFrom, textName, textBody)"
            


