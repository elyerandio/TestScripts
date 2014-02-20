import android

droid = android.Android()
mylocation={}               # Store last location shown.

def showMessage(msg):
    droid.dialogCreateAlert('Location', msg)
    droid.dialogSetPositiveButtonText('Geocode')
    droid.dialogShow()

def showLocation(data):
    global mylocation
    if data.has_key('gps') and data['gps'] != None:
        location = data['gps']
    elif data.has_key('network') and data['network'] != None:
        location = data['network']
    else:
        showMessage('No location data')
        return
    mylocation = location
    showMessage("Location: %(provider)s\nLatitude=%(latitude)0.5f,Longitude=%(longitude)0.5f"\
                % location)

def getGeocode():
    global mylocation
    print mylocation
    showMessage('Getting geocode')
    result = droid.geocode(mylocation['latitude'],mylocation['longitude']).result
    s = "Geocode"
    if result == None or len(result) < 1:
        s = s + "\nUnknown"
    else:
        result = result[0]
        for k in result:
            s = s + "\n" + k +"=" + str(result[k])
    showMessage(s)

def eventLoop():
    while True:
        event = droid.eventWait().result
        name = event['name']
        data = event['data']
        if name == 'location':
            showLocation(data)
        elif name == 'dialog':
            if data.has_key('canceled'):
                break
            elif data.has_key('which'):
                if data['which'] == 'positive':
                    getGeocode()

droid.startLocating()
# It will take a little while to actually get a fresh location
# so start off using last known.
showLocation(droid.getLastKnownLocation().result)
eventLoop()
droid.stopLocating()
droid.dialogDismiss()
