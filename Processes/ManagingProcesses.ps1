<#
Примеры команд для управления процессами
Дополнительную информацию можно найти здесь: https://docs.microsoft.com/en-us/powershell/scripting/samples/managing-processes-with-process-cmdlets?view=powershell-7.1
#>

# 1. Получение списка всех активных процессов
Get-Process
<# Пример вывода
NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
------    -----      -----     ------      --  -- -----------
    16    13,52      19,33       0,00    4808   0 AdjustService
    33    56,60      27,76     109,02   18204   1 Agent
    15     3,80      12,36       0,00    5232   0 AGMService
    14     3,52      12,30       0,00    5216   0 AGSService
    51    91,05      96,21      14,02   15216   1 ApCent
    28    28,86      34,76       0,23   16380   1 ApplicationFrameHost
    11     8,20      14,98       0,06   23244   0 audiodg
#>

# 2. Получение информации о конкретном процессе
Get-Process -Id 18204
<# Пример вывода
 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
     33    56,67      27,79     109,20   18204   1 Agent
#>

# 3. Получение процессов по имени (полному или по шаблону)
Get-Process -Name rph*
<# Пример вывода
 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
     97    73,46      88,60       0,00    6804   0 rphost

Также можно применить несколько условий по отбором по имени.
#>
Get-Process -Name rph*,ragent,rmngr
<# Пример вывода
 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
     73    46,81      34,77       0,00    1172   0 ragent
    108   108,90      64,94       0,00   17296   0 rmngr
     97    73,64      88,70       0,00    6804   0 rphost
#>

# 4. Остановка процессов по имени
Stop-Process -Name rphost

# 5. Остановка процессов, которые не отвечают
Get-Process -Name rphost | Where-Object -FilterScript {$_.Responding -eq $false} | Stop-Process

# 6. Остановка процесса по тексту в заголовке. Может быть полезно для завершения процессов, у которых "всплыла" ошибка с Visual C++ Runtime.
$processData = Get-Process | Where-Object { $_.mainwindowhandle -ne 0 -and $_.ProcessName -eq '<Отбор по имени процесса>' } | Select-Object MainWindowTitle, ProcessName, Id

$processData | ForEach-Object {
    # Проверяем наличие нужного текста в заголовке приложения
    if ($_.MainWindowTitle -like '*Visual C++*') {
        Stop-Process -Id $_.Id
    }
}
