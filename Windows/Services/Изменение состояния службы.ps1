# Остановка службы MSSQLSERVER
Stop-Service -Name MSSQLSERVER

# Запуск службы MSSQLSERVER
Start-Service -Name MSSQLSERVER

# Приостановка службы MSSQLSERVER
Suspend-Service -Name MSSQLSERVER

# Перезапуск службы MSSQLSERVER
Restart-Service -Name MSSQLSERVER

# Перезапуск нескольких служб
Get-Service | Where-Object -FilterScript {$_.CanStop} | Restart-Service

# Перезапуск службы на удаленном компьютере 
Invoke-Command -ComputerName YourServerName {Restart-Service MSSQLSERVER}

# Запуск службы, если она остановлена
Get-Service MSSQLSERVER | Where-Object -FilterScript {$_.status -eq 'stopped'} | Start-Service