import android
import time
import datetime

droid = android.Android()
droid.startLocating()
time.sleep(60)
loc = droid.readLocation()

if 'gps' in loc.result:
    lat = str(loc.result['gps']['latitude'])
    lon = str(loc.result['gps']['longitude'])
    via = 'gps'
else:
    lat = str(loc.result['network']['latitude'])
    lon = str(loc.result['network']['longitude'])
    via = 'network'
    
print via + "\nlatitude=" + lat + "\nlongitude=" + lon

# Get geocode
result = droid.geocode(lat, lon).result
geo = 'Geocode'
if result == None or len(result) < 1:
    geo = geo + "\nlatitude=" + lat + "\nlongitude=" + lon
else:
    result = result[0]
    for k in result:
        geo = geo + "\n" + k + '=' + str(result[k])

droid.stopLocating()
now = str(datetime.datetime.now())
outString = 'I am here (' + via + ') : ' + now + "\n" + geo
print outString
droid.smsSend('09209387580', outString)
