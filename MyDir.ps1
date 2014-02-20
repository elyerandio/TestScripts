if ($args.count -ne 1)
{
    write-host 'Missing Parameter!' -foregroundcolor 'Red'
    exit
}

$folderPath = $args[0]

foreach ($i in get-childitem $folderPath)
{
    if($i.mode.substring(0,1) -eq 'd')
    {
        write-host $i.name -foregroundcolor 'Yellow'
    }
    else
    {
        write-host $i.name -foregroundcolor 'Green'
    }
}
