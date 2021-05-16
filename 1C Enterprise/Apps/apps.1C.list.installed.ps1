<#
Список установленных версий платформы 1С
#>

$installedApps = New-Object System.Collections.ArrayList

Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  
Where-Object {  ($_.DisplayName -like "*1C:Предприятие*") -or ($_.DisplayName -like "*1C:Enterprise*") } |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation |
ForEach-Object {
    $installedApps.Add(
        [PSCustomObject] @{
            'DisplayName' = $_.DisplayName
            'DisplayVersion' = $_.DisplayVersion
            'Publisher' = $_.Publisher
            'InstallDate' = $_.InstallDate
            'InstallLocation' = $_.InstallLocation
        }
    ) | Out-Null;
}

Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object {  ($_.DisplayName -like "*1C:Предприятие*") -or ($_.DisplayName -like "*1C:Enterprise*") } |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation |
ForEach-Object {
    $installedApps.Add(
        [PSCustomObject] @{
            'DisplayName' = $_.DisplayName
            'DisplayVersion' = $_.DisplayVersion
            'Publisher' = $_.Publisher
            'InstallDate' = $_.InstallDate
            'InstallLocation' = $_.InstallLocation
        }
    ) | Out-Null;
}

$installedApps | Format-Table –AutoSize

<# Пример вывода

DisplayName                             DisplayVersion Publisher InstallDate InstallLocation
-----------                             -------------- --------- ----------- ---------------
1C:Предприятие 8 (x86-64) (8.3.16.1063) 8.3.16.1063    1С-Софт   20200106    C:\Program Files\1cv8\8.3.16.1063\
1C:Предприятие 8 (8.3.12.1924)          8.3.12.1924    1С-Софт   20200224    C:\Program Files (x86)\1cv8\8.3.12.1924\
1C:Предприятие 8 (8.3.5.1517)           8.3.5.1517     1C        20200110    C:\Program Files (x86)\1cv8\8.3.5.1517\
1C:Предприятие 8 (8.3.6.2530)           8.3.6.2530     1C        20200221    C:\Program Files (x86)\1cv8\8.3.6.2530\
#>