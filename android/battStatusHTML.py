import android
import time

# Simple HTML template using pythons format string syntax.
template = '''<html><head><title>Battery Data</title></head>
<body>
<h1>Battery Status</h1>
<ul>
<li><strong>Status: %(status)s</li>
<li><strong>Temperature: %(temperature)s</li>
<li><strong>Level: %(level)s</li>
<li><strong>Plugged In: %(plugged)s</li>
</ul>
</body></html>'''

if __name__ == "__main__":
    droid = android.Android()

    # Wait until we have readings from the battery.
    droid.batteryStartMonitoring()
    result = None
    while result is None:
        result = droid.readBatteryData().result
        time.sleep(0.5)

    # Write out the HTML with the values from our battery reading.
    f = open('/sdcard/sl4a/scripts/battstats.html','w')
    f.write(template % result)
    f.close()

    # Show the resulting HTML page.
    droid.webViewShow('/sdcard/sl4a/scripts/battstats.html')
