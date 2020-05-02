# Список всех служб
Get-Service

# Поиск по имени
Get-Service -Name *SQL*

# Пример вывода
#Status   Name               DisplayName                           
#------   ----               -----------                           
#Running  MSSQL$MSSQLSERV... SQL Server (MSSQLSERVER2008)          
#Running  MSSQL$MSSQLSERV... SQL Server (MSSQLSERVER2012)          
#Running  MSSQLFDLauncher    SQL Full-text Filter Daemon Launche...
#Running  MSSQLSERVER        SQL Server (MSSQLSERVER)              
#Stopped  MSSQLServerADHe... Служба поддержки Active Directory с...
#Running  MSSQLServerOLAP... Службы SQL Server Analysis Services...
#Stopped  SQLAgent$MSSQLS... Агент SQL Server (MSSQLSERVER2008)    
#Stopped  SQLAgent$MSSQLS... Агент SQL Server (MSSQLSERVER2012)    
#Stopped  SQLBrowser         Обозреватель SQL Server               
#Running  SQLSERVERAGENT     Агент SQL Server (MSSQLSERVER)        
#Running  SQLTELEMETRY       SQL Server CEIP service (MSSQLSERVER) 
#Running  SQLWriter          SQL Server, службы синхронизации ко...

# Поиск по отображаемому имени
Get-Service -DisplayName *SQL*

# Получение информации о службах на удаленном компьютере
Get-Service -ComputerName YourServername

# Получение информации о службах, которые необходимы для службы MSSQLSERVER
Get-Service -Name MSSQLSERVER -RequiredServices

# Получение служб, которым требуется служба MSSQLSERVER
Get-Service -Name MSSQLSERVER -DependentServices

# Получение всех служб, которые имеют зависимости, а также вывод в форматированную таблицу
Get-Service -Name * | Where-Object {$_.RequiredServices -or $_.DependentServices} |
  Format-Table -Property Status, Name, RequiredServices, DependentServices -auto