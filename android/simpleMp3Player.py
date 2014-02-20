import android, sys, os

droid = android.Android()

def showDialog():
    volume = droid.getMediaVolume().result
    droid.dialogCreateSeekBar(volume, maxvolume, "Media Play", "Volume")
    if droid.mediaIsPlaying("mp3").result:
        caption="Pause"
    else:
        caption="Play"

    droid.dialogSetPositiveButtonText(caption)
    droid.dialogSetNegativeButtonText("Rewind")
    droid.dialogShow()

def eventLoop():
    while True:
        event = droid.eventWait().result
        print event
        data = event['data']
        if event['name'] == 'dialog':
            if data.has_key('canceled'):
                break
            which = data['which']
            if which == 'seekbar':
                droid.setMediaVolume(data['progress'])
            elif which == 'positive':
                if droid.mediaIsPlaying("mp3").result:
                    droid.mediaPlayPause('mp3')
                else:
                    droid.mediaPlayStart('mp3')
                showDialog()
            elif which == 'negative':
                droid.mediaPlaySeek(0, 'mp3')
                showDialog()

def showError(msg):         # Display an error message
    droid.dialogCreateAlert('Error', msg)
    droid.dialogShow()
    droid.dialogGetResponse()

def findMp3():              # Search sdcard for an mp3 file
    mylist = []
    names = []
    for root, dirs, files in os.walk("/sdcard/Music"):
        print "root=",root
        print "dirs=",dirs
        print "files=",files

        for name in files:
            fname, fext = os.path.splitext(name)
            print "name=",name,"\tfname=",fname,"\tfext=",fext
            if fext.lower() == '.mp3':
                print "append=",os.path.join(root, name)
                mylist.append(os.path.join(root, name))
                names.append(fname)
    droid.dialogCreateAlert('MP3 File')
    droid.dialogSetItems(names)
    droid.dialogShow()
    result = droid.dialogGetResponse().result
    droid.eventClearBuffer()            # Get rid of unwanted events
    print result
    if not result.has_key('canceled'):
        return mylist[result['item']]
    else:
        return None

maxvolume = droid.getMaxMediaVolume().result
mp3 = findMp3()
if mp3 == None:
    showError('No media file chosen')
    sys.exit(0)
if not droid.mediaPlay("file://" + mp3, "mp3", False).result:
    showError("Can't open mp3 file.")
    sys.exit(0)
showDialog()
eventLoop()
droid.mediaPlayClose('mp3')
droid.dialogDismiss()

