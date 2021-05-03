<#
Перед работой скрипта сохранения информации о рабочих процессах 1С необходимо создать базу данных PostgreSQL
с соответствующей таблицей и индексом.

CREATE TABLE public.work_processes1c (
	hostname varchar(25) NOT NULL,
	main_port int8 NOT NULL,
	sync_port int8 NOT NULL,
	"enable" bool NOT NULL,
	running int8 NOT NULL,
	connections int8 NOT NULL,
	started_at timestamp(0) NOT NULL,
	avg_call_time float8 NOT NULL,
	avg_server_call_time float8 NOT NULL,
	avg_db_call_time float8 NOT NULL,
	avg_back_call_time float8 NOT NULL,
	avg_lock_call_time float8 NOT NULL,
	selection_size int8 NOT NULL,
	avg_threads float8 NOT NULL,
	capacity int8 NOT NULL,
	memory_size int8 NOT NULL,
	memory_excess_time int8 NOT NULL,
	available_perfomance int8 NOT NULL,
	pid int8 NOT NULL,
	use int8 NOT NULL,
	is_enable bool NOT NULL,
	"period" timestamp(0) NOT NULL,
	servername varchar(25) NOT NULL
);
CREATE INDEX work_processes1c_period_idx ON public.work_processes1c USING btree (period, servername, hostname);

Также нужно установить ODBC-драйвер для работы с PostgreSQL: https://odbc.postgresql.org/
#>

# Настройки сервера PostgreSQL
$DBIP = "127.0.0.1" # Адрес сервера PostgreSQL
$DBPort = 5432 # Порт сервера PostgreSQL
$DBName = "MyDatabase" # База данных для сохранения информации
$DBUser = "MyUser" # Пользователь PostgreSQL
$DBPass = "MyPassword" # Пароль пользователь PostgreSQL
$DBConnectionString = "Driver={PostgreSQL UNICODE};Server=$DBIP;Port=$DBPort;Database=$DBName;Uid=$DBUser;Pwd=$DBPass;"

# Настройки сервера 1С
$server1CSettings = @()
# Добавляем настройки сервера 1С для сбора данных.
# Аналогично можно добавить сколько угодно серверов
$server1CSettings += New-Object PSCustomObject -Property @{
    agentPort = 1540 # Порт сервера 1С
    agentAddress = "my.server.1c.ru" # Адрес сервера 1С
    clusterAdminName = "" # Имя администратора кластера (пустой, если его нет)
    clusterAdminPassword = "" # Пароль администратора кластера (пустой, если его нет)
} # Сервер 1С для сбора данных

# Получаем информацию о рабочих процессах для каждого сервера
$server1CSettings | ForEach-Object {  

    $COMConnector = $null
    try {
        $COMConnector = New-Object -COMObject "V83.COMConnector"
        # Для 8.2
        #$COMConnector = New-Object -COMObject "V82.COMConnector"
        Write-Host "Компонента "COMConnector" зарегистрирована и готова к использованию." -ForegroundColor Green;
    } 
    catch {
        Write-Host "Компонента "V82.COMConnector" не зарегистрирована." -ForegroundColor Red;
    }
    $DBConn = $null
    try {
        $DBConn = New-Object System.Data.Odbc.OdbcConnection
        $DBConn.ConnectionString = $DBConnectionString
        $DBConn.Open();
        Write-Host "Установлено соединение с базой данных мониторинга." -ForegroundColor Green;
    }
    catch {
        Write-Host "Не удалось установить соединение с базой данных мониторинга." -ForegroundColor Red;
        $DBConn = $null
    }

    $agentAddress = $_.agentAddress
    $agentPort = $_.agentPort
    $clusterAdminName = $_.clusterAdminName
    $clusterAdminPassword = $_.clusterAdminPassword
    $fullAgentAddress = "tcp://" + $agentAddress + ":" + $agentPort;

    $fullAgentAddress

    try {
        if($null -ne $COMConnector -and $null -ne $DBConn) {
            $serverAgent = $COMConnector.ConnectAgent($fullAgentAddress);
            $clusterList = $ServerAgent.GetClusters();
            foreach ($cluster in $clusterList) {
                $serverAgent.Authenticate($Cluster, $clusterAdminName, $clusterAdminPassword)        

                $period = Get-Date
                $workingProcesses = $serverAgent.GetWorkingProcesses($cluster)
                foreach ($workProcess in $workingProcesses) {
                    
                    $DBCmd = $DBConn.CreateCommand()
                    $DBCmd.Connection = $DBConn
                    $insertQuery = 
@"
        INSERT INTO work_processes1c
        (
            period,
	        servername,
	        hostname,    
	        main_port,
	        sync_port,
	        enable,
	        running,
	        connections,
	        started_at,
	        avg_call_time,
	        avg_server_call_time,
	        avg_db_call_time,
	        avg_back_call_time,
	        avg_lock_call_time,
	        selection_size,
	        avg_threads,
	        capacity,
	        memory_size,
	        memory_excess_time,
	        available_perfomance,
	        pid,
	        use,
	        is_enable
        )
        VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
"@
                    $DBCmd.CommandText = $insertQuery

                    [void]$DBCmd.Parameters.Add("@period", [System.Data.Odbc.OdbcType]::varchar, 26)
                    [void]$DBCmd.Parameters.Add("@servername", [System.Data.Odbc.OdbcType]::varchar, 25)
                    [void]$DBCmd.Parameters.Add("@hostname", [System.Data.Odbc.OdbcType]::varchar, 25)
                    [void]$DBCmd.Parameters.Add("@main_port", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@sync_port", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@enable", [System.Data.Odbc.OdbcType]::Bit)
                    [void]$DBCmd.Parameters.Add("@running", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@connections", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@started_at", [System.Data.Odbc.OdbcType]::varchar, 26)
                    [void]$DBCmd.Parameters.Add("@avg_call_time", [System.Data.Odbc.OdbcType]::Double)
                    [void]$DBCmd.Parameters.Add("@avg_server_call_time", [System.Data.Odbc.OdbcType]::Double)
                    [void]$DBCmd.Parameters.Add("@avg_db_call_time", [System.Data.Odbc.OdbcType]::Double)
                    [void]$DBCmd.Parameters.Add("@avg_back_call_time", [System.Data.Odbc.OdbcType]::Double)
                    [void]$DBCmd.Parameters.Add("@avg_lock_call_time", [System.Data.Odbc.OdbcType]::Double)
                    [void]$DBCmd.Parameters.Add("@selection_size", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@avg_threads", [System.Data.Odbc.OdbcType]::Double)
                    [void]$DBCmd.Parameters.Add("@capacity", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@memory_size", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@memory_excess_time", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@available_perfomance", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@pid", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@use", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@is_enable", [System.Data.Odbc.OdbcType]::Bit)

					# Дата получения информации о рабочих процессах
                    $DBCmd.Parameters["@period"].Value = $period.ToString("yyyy-MM-dd HH:mm:ss")
					# Имя сервера 1С
                    $DBCmd.Parameters["@servername"].Value = $agentAddress
					# Содержит имя или IP-адрес компьютера, на котором должен быть запущен рабочий процесс.
                    $DBCmd.Parameters["@hostname"].Value = $workProcess.HostName
					# Содержит номер основного IP-порта рабочего процесса. Этот порт выделяется динамически 
					# при старте рабочего процесса из диапазонов портов, определенных для соответствующего рабочего сервера.
                    $DBCmd.Parameters["@main_port"].Value = $workProcess.MainPort
                    $DBCmd.Parameters["@sync_port"].Value = $workProcess.SyncPort
					# Признак включения рабочего процесса
                    $DBCmd.Parameters["@enable"].Value = $workProcess.Enable
					# 0 – процесс неактивен (либо не загружен в память, либо не может выполнять клиентские запросы); 1 – процесс активен (работает).
                    $DBCmd.Parameters["@running"].Value = $workProcess.Running
					# Connections
                    $DBCmd.Parameters["@connections"].Value = $workProcess.connections
					# Содержит момент запуска рабочего процесса. Если процесс не запущен, то содержит нулевую дату.
                    $DBCmd.Parameters["@started_at"].Value = $workProcess.StartedAt.ToString("yyyy-MM-dd HH:mm:ss")
					# Показывает среднее время обслуживания рабочим процессом одного клиентского обращения. 
					# Оно складывается из: значений свойств AvgServerCallTime, AvgDBCallTime, AvgLockCallTime.
                    $DBCmd.Parameters["@avg_call_time"].Value = $workProcess.AvgCallTime
					# Показывает среднее время, затрачиваемое самим рабочим процессом на выполнение одного клиентского обращения.
                    $DBCmd.Parameters["@avg_server_call_time"].Value = $workProcess.AvgServerCallTime
					# Показывает среднее время, затрачиваемое рабочим процессом на обращения к серверу баз данных при выполнении одного клиентского обращения.
                    $DBCmd.Parameters["@avg_db_call_time"].Value = $workProcess.AvgDBCallTime					
                    $DBCmd.Parameters["@avg_back_call_time"].Value = $workProcess.AvgBackCallTime
					# Показывает среднее время обращения к менеджеру блокировок.
                    $DBCmd.Parameters["@avg_lock_call_time"].Value = $workProcess.AvgLockCallTime
					# Количество вызовов, по которым посчитана статистика.
                    $DBCmd.Parameters["@selection_size"].Value = $workProcess.SelectionSize
					# Показывает среднее количество клиентских потоков, исполняемых рабочим процессом кластера.
                    $DBCmd.Parameters["@avg_threads"].Value = $workProcess.AvgThreads
					# Относительная производительность процесса. 
					# Может находиться в диапазоне от 1 до 1000. Используется в процессе выбора рабочего процесса, к которому будет подсоединен очередной клиент. 
                    $DBCmd.Parameters["@capacity"].Value = $workProcess.Capacity
					# Содержит объем виртуальной памяти, занимаемой рабочим процессом, в килобайтах.
                    $DBCmd.Parameters["@memory_size"].Value = $workProcess.MemorySize
					# Содержит время, в течение которого объем виртуальной памяти рабочего процесса превышает критическое значение, установленное для кластера, в секундах.
                    $DBCmd.Parameters["@memory_excess_time"].Value = $workProcess.MemoryExcessTime
					# Средняя за последние 5 минут доступная производительность. 
					# Определяется по времени реакции рабочего процесса на эталонный запрос.
					# В соответствии с доступной производительностью кластер серверов принимает решение о распределении клиентов между рабочими процессами.
                    $DBCmd.Parameters["@available_perfomance"].Value = $workProcess.AvailablePerfomance
					# Идентификатор активного рабочего процесса в терминах операционной системы.
                    $DBCmd.Parameters["@pid"].Value = $workProcess.PID
					<#
					Определяет использование рабочего процесса кластером. Устанавливается администратором. 
						Возможные значения:
						0 – не использовать, процесс не должен быть запущен;
						1 – использовать, процесс должен быть запущен;
						2 – использовать как резервный, процесс должен быть запущен только при невозможности запуска процесса со значением 1 этого свойства.
					#>
                    $DBCmd.Parameters["@use"].Value = $workProcess.Use
					
                    if($null -ne $workProcess.IsEnables)
                    {
                        $DBCmd.Parameters["@is_enable"].Value = $workProcess.IsEnables
                    } else
                    {
                        $DBCmd.Parameters["@is_enable"].Value = -1
                    }

                    [void]$DBCmd.ExecuteNonQuery()
                }
            }
        }                
    } 
    catch {
        Write-Host "Ошибка при выполнении скрипта." -ForegroundColor Red;
        Write-Host "Подробно:" -ForegroundColor Red
        Write-Host $Error[0] -ForegroundColor Red
    }

    $COMConnector = $null
    $DBConn = $null
}