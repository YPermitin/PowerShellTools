<#
Простейшая настройка удаленного доступа через PSRemoting
Внимание! Скрипт не для рабочего окружения.

Подробнее можно прочитать:
https://www.howtogeek.com/117192/how-to-run-powershell-commands-on-remote-computers/
https://docs.microsoft.com/ru-ru/powershell/module/microsoft.powershell.core/about/about_remote_faq?view=powershell-7.1#can-i-create-a-persistent-connection
https://docs.microsoft.com/ru-ru/powershell/scripting/learn/remoting/running-remote-commands?view=powershell-7.1
#>

# Включаем использование PSRemoting
Enable-PSRemoting -Force

# Включаем доступ для других машин (в этом случае для всех)
Set-Item wsman:\localhost\client\trustedhosts *

# Перезапускаем службу WinRM
Restart-Service WinRM

# Проверяем доступ
Test-WsMan HostNameForTest