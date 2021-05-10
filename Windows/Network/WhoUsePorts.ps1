<#
Пример скрипта для получения информации о том кто и какой порт использует.

Можно искать информацию для конкретного порта или процесса.
#>

netstat -ano | 
Where-Object{$_ -match 'LISTENING|UDP'} | 
ForEach-Object {
    $split = $_.Trim() -split "\s+"
    [pscustomobject][ordered]@{
        "Protocol" = $split[0]
        "LocalAddress" = $split[1]
        "ForeignAddress" = $split[2]
        # Some might not have a state. Check to see if the last element is a number. If it is ignore it
        "State" = if($split[3] -notmatch "\d+"){$split[3]}else{""}
        # The last element in every case will be a PID
        "ProcessName" = $(Get-Process -Id $split[-1]).ProcessName
        "ProcessId" = $split[-1]
    }
} |
# Раскомментировать нужные условия
# Where-Object{$_.ProcessId -eq 15151} | # Фильтр по идентификатору процесса
# Where-Object{$_.ProcessName -like 'rmng*'} | # Фильтр по имени приложения
# Where-Object{$_.LocalAddress -like '*:1560'} | # Фильтр по порту
Select Protocol, LocalAddress, ForeignAddress, State, ProcessName, ProcessId