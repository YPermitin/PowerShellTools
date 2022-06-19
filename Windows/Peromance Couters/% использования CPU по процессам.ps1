# Количество ядер в системе
$cpuCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
# Локалб системы
$locale = $PSUICulture
# Получаем список идентификаторов процессов и значения их % использования CPU с учетом локали
if($locale -eq "ru-RU")
{
    $procIds = (Get-Counter "\Процесс(*)\Идентификатор процесса" -ErrorAction SilentlyContinue).CounterSamples
    $procUsage = (Get-Counter "\Процесс(*)\% загруженности процессора" -ErrorAction SilentlyContinue).CounterSamples
} else
{
    $procIds = (Get-Counter "\Process(*)\ID Process" -ErrorAction SilentlyContinue).CounterSamples
    $procUsage = (Get-Counter "\Process(*)\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples
}

# Для каждого идентификатора процесса определяем % использования ЦП
$procIds | ForEach-Object {
    # Преобразуем путь к идентификатору процесса на путь к позкателю загруженности ЦП d %
    if($locale -eq "ru-RU")
    {
        $procUsageCounterName = $_.Path -replace "\\идентификатор процесса$", "\% загруженности процессора"
    } else
    {
        $procUsageCounterName = $_.Path -replace "\\id process$", "\% processor time"
    }
    # В списке ранее полученных показателей ОС находим нужны по сформированному пути
    $procUsageInfo = $procUsage | Where-Object { $_.Path -eq $procUsageCounterName }    
    # Адаптируем значение с учетом количества ядер
    $cpuUsagePercent = $procUsageInfo.CookedValue / $cpuCores    
    # Округляем до сотых
    $cpuUsagePercent = [Math]::Round($cpuUsagePercent, 2)
    
    # Выводим результат
    Write-Host "PID: $($_.CookedValue), CPU%: $($cpuUsagePercent)"
}