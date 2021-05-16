<#
Регистрация и запуск консоли администрирования нужной версии платформы 1С
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

Write-Host "Найденные версии платформы 1С:"
$menu = @{}
for ($i=1;$i -le $installedApps.count; $i++) 
{ 
    Write-Host "$i. $($installedApps[$i-1].DisplayName) ($($installedApps[$i-1].InstallLocation))" 
    $menu.Add($i,($installedApps[$i-1]))
}
[int]$answer = Read-Host 'Выберите установленную платформу 1С'
$selection = $menu.Item($answer)

if($null -ne $selection)
{
    $installLocation = $selection.InstallLocation
    $redminPath = Join-Path -Path $installLocation -ChildPath "bin\radmin.dll"
    $1cv8Path = (get-item $installLocation).parent.FullName
    $commonPath = Join-Path -Path $1cv8Path -ChildPath "common"    
    $consolePath = ""    

    $foundMscFiles = Get-Childitem –Path $commonPath | Where-Object { $_.Name -like "1CV8 Servers*.msc" }
    
    if($null -ne $foundMscFiles -and $foundMscFiles.Length -ge 0)
    {
        $consolePath = Join-Path -Path $commonPath -ChildPath $foundMscFiles[0].Name
    } else
    {
        Write-Host "Не найдена оснастка консоли администрирования (1CV8 Servers*.msc) в каталоге: $commonPath" -BackgroundColor Red
        return
    }    

    if(Test-Path $redminPath)
    {
        Write-Host "Начало регистрации компоненты radmin.dll" -BackgroundColor Blue
        regsvr32 /s $redminPath
        Write-Host "Успешно зарегистрирована компонента radmin.dll" -BackgroundColor Green

        C:\Windows\System32\mmc.exe $consolePath
    } else
    {
        Write-Host "Не найдена компонент radmin.dll по пути: $redminPath" -BackgroundColor Red
    }
} else
{
    Write-Host "Выбрано некорректное значение." -BackgroundColor Red
}
