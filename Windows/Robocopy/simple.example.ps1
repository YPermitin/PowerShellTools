<#
Официальная документация: https://docs.microsoft.com/ru-ru/windows-server/administration/windows-commands/robocopy
#>

$source="C:\source"
$dest="D:\destination"

$what = @("/COPYALL","/B","/SEC","/MIR")
$options = @("/R:0","/W:0","/NFL","/NDL")

$cmdArgs = @("$source","$dest",$what,$options)
robocopy @cmdArgs