import android

droid = android.Android()
arg = droid.getIntent().result['extras']['%Battery']
print "arg is ", arg
