# Счетчики производительности Windows

[Официальная документация](https://docs.microsoft.com/ru-ru/windows/win32/perfctrs/performance-counters-portal) даст ответы на все вопросы. Здесь соберем некоторые моменты по работе с ними.

Также в этом разделе находятся некоторые полезные скрипты.

## PowerShell

Работу со счетчиками производительности из PowerShell выполняется с помощью команды [Get-Counter](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-counter?view=powershell-7.2).

Например, получение всех доступных счетчиков производительности в системе.

```pwsh
Get-Counter -ListSet *
```

Или получение % использования ЦП с интервалом обновления в 2 секунды (SampleInterval) и максимальным количеством проверок (MaxSamples) равным 3.

```pwsh
Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2 -MaxSamples 3
```

Или получение значения счетчика на текущий момент времени.

```pwsh
Get-Counter -Counter "\Процессор(_Total)\% загруженности процессора"
```

И так далее.

## Локализация

Имена счетчиков производительности могут отличаться в зависимости от локализации в системе Windows. Например, если в англоязычной версии:

```
\Processor(_Total)\% Processor Time
```

То в русскоязычной версии:

```
\Процессор(_Total)\% загруженности процессора
```

## Полезные ссылки

* [PowerShellTools](https://github.com/YPermitin/PowerShellTools) - репозиторий с полезными скриптами, материалами по PowerShell.
* [Use PowerShell to list all Windows Performance Counters and their numeric IDs](https://daniel.streefkerkonline.com/2016/02/18/use-powershell-to-list-all-windows-performance-counters-and-their-numeric-ids/)
* [Счетчики производительности Windows](https://www.zabbix.com/documentation/current/ru/manual/config/items/perfcounters) - в документации по Zabbix.
* [PowerShell: the issues you bump into when using Get-Counter and Measure-Object aggregation](https://wiert.me/2019/07/17/powershell-the-issues-you-bump-into-when-using-get-counter-and-measure-object-aggregation/)
