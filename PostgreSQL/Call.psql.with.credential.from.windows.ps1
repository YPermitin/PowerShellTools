<#
Пример вызова PSQL из скрипта с установкой логина и пароля пользователя
#>

# Путь PostgreSQL
$pgDirectory = "C:\Program Files\PostgreSQL\13\bin"
# Устанавливаем текущий каталог PostgreSQL для простого вызова утилиты psql
# Альтернативный подход - добавить этот каталог в параметры окружения
Set-Location $pgDirectory;
# База данных для подключения
$pgDatabase = "postgres"
# Имя пользователя
$pgUser = "postgres"
# Пароль пользователя
$pgPassword = 'Pas$w0rd'
# psql не имеет параметра установки пароля явно в параметрах вызова,
# но вместо этого можно установить пароль через параметр окружения
$env:PGPASSWORD = $pgPassword;

# Выполнение произвольной команды
.\psql.exe -p 5432 -U $pgUser -d $pgDatabase -c 'select now()'

# Завершение всех соединений с указанной базой данных
#.\psql.exe -p 5432 -U $pgUser -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = '$pgDatabase';"

# Выполнение скрипта из файла. Таким же образом можно выполнить восстановление из дампа (*.sql)
#.\psql.exe -p 5432 -U $pgUser -d $pgDatabase -1 -f $scriptFilePath