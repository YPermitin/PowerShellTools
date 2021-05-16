<#
Пример выполнения простейшей команды
#>

# Перезапускаем удаленный компьютер
Invoke-Command -ComputerName HostName -ScriptBlock { 
    Restart-Computer -Force
} -credential UserName