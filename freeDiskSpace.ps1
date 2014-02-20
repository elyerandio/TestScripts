get-wmiobject win32_logicalDisk -filter "DriveType=3" | format-table `
	SystemName, Name, `
	@{Name="Size (GB)"; Expression={[math]::round($($_.Size/1GB), 2)}}, `
	@{Name="Free (GB)"; Expression={[math]::round($($_.FreeSpace/1GB), 2)}} `
	-auto
