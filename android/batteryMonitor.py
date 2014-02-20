import android

droid = android.Android()
droid.batteryStartMonitoring()
health = { 1:"Unknown", 2:"Good", 3:"Overhead", 4:"Dead", 5:"Over voltage", 6:"Failure" }
plug = { -1:"Unknown", 0:"Unplugged", 1:"AC Charger", 2:"USB Port" }
status = { 1:"Unknown", 2:"Charging", 3:"Discharging", 4:"Not Charging", 5:"Full" }
droid.eventWaitFor('battery')
droid.eventClearBuffer()        # eventWaitFor leaves event in queue

msg = []
msg.append("Voltage:     %s mV" % droid.batteryGetVoltage().result)
msg.append("Present:     %s" % droid.batteryCheckPresent().result)
msg.append("Health:      %s" % health[droid.batteryGetHealth().result])
msg.append("Level:       %s" % droid.batteryGetLevel().result)
msg.append("Plug Type:   %s" % plug[droid.batteryGetPlugType().result])
msg.append("Status:      %s" % status[droid.batteryGetStatus().result])
msg.append("Technology:  %s" % droid.batteryGetTechnology().result)
temp = droid.batteryGetTemperature().result / 10.0
msg.append("Temperature: %.1f C" % temp)
droid.batteryStopMonitoring()
droid.dialogCreateAlert('Battery Monitoring')
droid.dialogSetItems(msg)
droid.dialogShow()
droid.dialogGetResponse().result
droid.dialogDismiss()
