import android

droid = android.Android()

fruits = ['apple', 'orange', 'banana', 'strawberry', 'mango', 'avocado']

droid.dialogCreateAlert('Pick One')
droid.dialogSetMultiChoiceItems(fruits)
droid.dialogSetPositiveButtonText('Done')
droid.dialogShow()
droid.dialogGetResponse()
ans = droid.dialogGetSelectedItems().result

print ans
print "You chose " + fruits[ans[0]]
