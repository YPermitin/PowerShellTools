<#
Пример запуска простого запроса с помощью DBATools
GitHub: https://github.com/sqlcollaborative/dbatools
#>

$instance = "localhost"

# Получаем список файлов баз данных
Get-DbaFile -SqlInstance $instance

# Читаем данные событий Extended Events
Get-DbaXESession -SqlInstance $instance -Session system_health | Read-DbaXEFile | Out-GridView

# Сбос доступа администратора
Reset-DbaAdmin -SqlInstance $instance -Login sqladmin -Verbose
Get-DbaDatabase -SqlInstance $instance -SqlCredential sqladmin