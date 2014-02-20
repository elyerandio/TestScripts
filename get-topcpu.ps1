## Uses get-process and returns the top 10 cpu using processes
## with the time in minutes

get-process | sort-object CPU -Descending | select-object -First 10 | Format-table Name, @{Label="CPU(Min)"; Expression={"{0:F3}" -f ($_.TotalProcessorTime.TotalMinutes) }} -AutoSize
