# Win32_NetworkAdapter. Disable / Enable Script"  
# Created by Daniel Klepner 

$filter = "AdapterType = 'Ethernet 802.3' and NetEnabled = 'True'"
$class = "Win32_NetworkAdapter"
$namespace = "root\cimv2"
$strComputer = "."


# Find all Active ethernet 802.3 network cards
$colItems = get-wmiobject -class $class -namespace $namespace -computername $strComputer –filter $filter 



# Disable  active network cards
foreach ($objItem in $colItems) {
      write-host $objItem.Description
	   $objItem.Disable()
}


Start-sleep 30

# Enable active network cards
foreach ($objItem in $colItems) {
      write-host $objItem.Description
	   $objItem.Enable()
}