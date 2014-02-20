import android

droid = android.Android()

fruits = ['apple', 'orange', 'banana', 'strawberry', 'mango', 'avocado']

droid.dialogCreateAlert('Pick One')
droid.dialogSetItems(fruits)
droid.dialogShow()
response = droid.dialogGetResponse().result['item']

#print "You chose " + fruits[response['item']]
print "You chose " + fruits[response]
