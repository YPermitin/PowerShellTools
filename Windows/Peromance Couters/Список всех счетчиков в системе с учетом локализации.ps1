<#
Получение списка всех досупных показателей производительности Windows в системе, в т.ч. с учетом локализации.

В результате получить объекты с информацией:
ID - числовой идентификатор части имени счетчика
NameLocalized - имя с учетом локализации
NameEng - имя на английском без учета локализации

Например:
Id	NameLocalized	NameEng
2	1847	1847
4	Система	System
6	Память	Memory
10	% загруженности процессора	% Processor Time
12	Операций чтения файлов/с	File Read Operations/sec
14	Операций записи файлов/с	File Write Operations/sec

Детальный пример сопоставления локализации можно посмотреть здесь:
https://gist.github.com/YPermitin/142a9a898304d294caf547c62f06ed8f
#>

$keyEnglish        = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\009'
$keyLocalized      = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage'
$countersEnglish   = (Get-ItemProperty -Path $keyEnglish -Name Counter).Counter
$countersLocalized = (Get-ItemProperty -Path $keyLocalized -Name Counter).Counter

$perfCountersEng = new-object "System.Collections.Generic.Dictionary[[int],[string]]"
$countersEnglishCount = $countersEnglish.Count / 2
for($num = 1; $num -le $countersEnglishCount; $num++)
{
    $indexId = $num * 2
    $indexName = $indexId - 1   
    $counterId = $countersEnglish[$indexId] 
    $counterName = $countersEnglish[$indexName]

    if($perfCountersEng.ContainsKey($counterId))
    {
        # Ничего не делаем
    } else
    {
        $perfCountersEng.Add($counterId, $counterName) | Out-Null
    }
}

$perfCountersLocalized = new-object "System.Collections.Generic.Dictionary[[int],[string]]"
$countersLocalizedCount = $countersLocalized.Count / 2
for($num = 1; $num -le $countersLocalizedCount; $num++)
{
    $indexId = $num * 2
    $indexName = $indexId - 1   
    $counterId = $countersLocalized[$indexId] 
    $counterName = $countersLocalized[$indexName]

    if($perfCountersLocalized.ContainsKey($counterId))
    {
        # Ничего не делаем
    } else
    {
        $perfCountersLocalized.Add($counterId, $counterName) | Out-Null
    }
}

$allPerfCounter = new-object "System.Collections.Generic.Dictionary[[int],[object]]"
foreach ($key in $perfCountersLocalized.Keys) { 
    $allPerfCounter.Add($key,
    [pscustomobject]@{
        NameRus=$perfCountersLocalized[$key];
        NameEng=""
    })
} 
foreach ($key in $perfCountersEng.Keys) { 
    if($allPerfCounter.ContainsKey($key))
    {
        $allPerfCounter[$key].NameEng = $perfCountersEng[$key]
    } else
    {
        $allPerfCounter.Add($key,
        [pscustomobject]@{
            NameLocalized= "";
            NameEng=$perfCountersEng[$key]
        })
    }    
} 

$allPerfCounter