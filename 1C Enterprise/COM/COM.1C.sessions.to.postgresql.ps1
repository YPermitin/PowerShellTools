<#
Перед работой скрипта сохранения информации о сеансах 1С необходимо создать базу данных PostgreSQL
с соответствующей таблицей и индексом.

CREATE TABLE public.sessions1c (
	servername varchar(25) NOT NULL,
	infobase varchar(25) NOT NULL,
	sessionid int8 NULL,
	started_at timestamp(0) NULL,
	last_active_at timestamp(0) NULL,
	host varchar(25) NULL,
	appid varchar(25) NULL,
	username varchar(50) NULL,
	work_process_id int8 NULL,
	connectionid int8 NULL,
	"period" timestamp(0) NOT NULL,
	db_proc_info int8 NULL,
	db_proc_took_at timestamp(0) NULL,
	db_proc_took int8 NULL,
	blocked_by_dbms int8 NULL,
	blocked_by_ls int8 NULL,
	duration_current_dbms int8 NULL,
	duration_last_5_min_dbms int8 NULL,
	duration_all_dbms int8 NULL,
	dbms_bytes_last_5_min int8 NULL,
	dbms_bytes_all int8 NULL,
	duration_current int8 NULL,
	duration_last_5_min int8 NULL,
	duration_all int8 NULL,
	calls_last_5_min int8 NULL,
	calls_all int8 NULL,
	bytes_last_5_min int8 NULL,
	bytes_all int8 NULL
);
CREATE INDEX sessions1c_period_idx ON public.sessions1c ("period" timestamp_ops,servername text_ops,infobase text_ops);

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

# Получаем информацию о сеансах для каждого сервера
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
                $serverSessionsData = $serverAgent.GetSessions($cluster);

                $serverSessionsData | ForEach-Object {                
                    $itemSession = $_;

                    $DBCmd = $DBConn.CreateCommand()
                    $DBCmd.Connection = $DBConn
                    $insertQuery = 
@"
        INSERT INTO sessions1c
        (
            period,
            servername,
            infobase,
            sessionid,
            started_at,
            last_active_at,
            host,
            appid,
            username,
            work_process_id,
            connectionid,
            db_proc_info,
            db_proc_took_at,
            db_proc_took,
            blocked_by_dbms,
            blocked_by_ls,
            duration_current_dbms,
            duration_last_5_min_dbms,
            duration_all_dbms,
            dbms_bytes_last_5_min,
            dbms_bytes_all,
            duration_current,
            duration_last_5_min,
            duration_all,
            calls_last_5_min,
            calls_all,
            bytes_last_5_min,
            bytes_all
        )
        VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
"@
                    $DBCmd.CommandText = $insertQuery

                    [void]$DBCmd.Parameters.Add("@period", [System.Data.Odbc.OdbcType]::varchar, 26)
                    [void]$DBCmd.Parameters.Add("@servername", [System.Data.Odbc.OdbcType]::varchar, 25)
                    [void]$DBCmd.Parameters.Add("@infobase", [System.Data.Odbc.OdbcType]::varchar, 25)
                    [void]$DBCmd.Parameters.Add("@sessionid", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@started_at", [System.Data.Odbc.OdbcType]::varchar, 26)
                    [void]$DBCmd.Parameters.Add("@last_active_at", [System.Data.Odbc.OdbcType]::varchar, 26)
                    [void]$DBCmd.Parameters.Add("@host", [System.Data.Odbc.OdbcType]::varchar, 25)
                    [void]$DBCmd.Parameters.Add("@appid", [System.Data.Odbc.OdbcType]::varchar, 25)
                    [void]$DBCmd.Parameters.Add("@username", [System.Data.Odbc.OdbcType]::varchar, 50)
                    [void]$DBCmd.Parameters.Add("@work_process_id", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@connectionid", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@db_proc_info", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@db_proc_took_at", [System.Data.Odbc.OdbcType]::varchar, 26)
                    [void]$DBCmd.Parameters.Add("@db_proc_took", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@blocked_by_dbms", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@blocked_by_ls", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@duration_current_dbms", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@duration_last_5_min_dbms", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@duration_all_dbms", [System.Data.Odbc.OdbcType]::Int)
                    [void]$DBCmd.Parameters.Add("@dbms_bytes_last_5_min", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@dbms_bytes_all", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@duration_current", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@duration_last_5_min", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@duration_all", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@calls_last_5_min", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@calls_all", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@bytes_last_5_min", [System.Data.Odbc.OdbcType]::BigInt)
                    [void]$DBCmd.Parameters.Add("@bytes_all", [System.Data.Odbc.OdbcType]::BigInt)
                    
                    # Дата получения информации о сеансах
                    $DBCmd.Parameters["@period"].Value = $period.ToString("yyyy-MM-dd HH:mm:ss")
                    # Имя сервера 1С
                    $DBCmd.Parameters["@servername"].Value = $agentAddress
                    # Содержит описание информационной базы, с которой установлен сеанс.
                    if($itemSession.infoBase -ne $null)
                    {
                        $DBCmd.Parameters["@infobase"].Value = $itemSession.infoBase.Name                                             
                    } else
                    {
                        $DBCmd.Parameters["@infobase"].Value = ""
                    }
                    # Содержит номер сеанса. Целое число, уникальное среди всех сеансов данной информационной базы.
                    $DBCmd.Parameters["@sessionid"].Value = $itemSession.SessionID   
                    # Дата/ время начала сеанса.
                    $DBCmd.Parameters["@started_at"].Value = $itemSession.StartedAt.ToString("yyyy-MM-dd HH:mm:ss")
                    # Дата/ время последней активности сеанса.
                    $DBCmd.Parameters["@last_active_at"].Value = $itemSession.LastActiveAt.ToString("yyyy-MM-dd HH:mm:ss")
                    # Содержит имя или адрес компьютера, установившего сеанс.
                    $DBCmd.Parameters["@host"].Value = $itemSession.Host
                    # Содержит идентификатор приложения, установившего сеанс.
                    $DBCmd.Parameters["@appid"].Value = $itemSession.AppID
                    # Содержит имя аутентифицированного пользователя информационной базы.
                    $DBCmd.Parameters["@username"].Value = $itemSession.userName 
                    # Идентификатор активного рабочего процесса в терминах операционной системы.               
                    if($null -ne $itemSession.process)
                    {
                        $DBCmd.Parameters["@work_process_id"].Value = $itemSession.process.PID
                    } else
                    {
                        $DBCmd.Parameters["@work_process_id"].Value = 0
                    }
                    # Содержит идентификатор соединения. Позволяет различить разные соединения, 
                    # установленные одним и тем же приложением с одного и того же клиентского компьютера.
                    if($null -ne $itemSession.connection)
                    {
                        $DBCmd.Parameters["@connectionid"].Value = $itemSession.connection.ConnID
                    } else
                    {
                        $DBCmd.Parameters["@connectionid"].Value = 0
                    }              
                    # Содержит номер соединения с СУБД в терминах СУБД в том случае, если в момент получения списка выполняется запрос к СУБД, 
                    # открыта транзакция или определены временные таблицы (это означает, что захвачено соединение с СУБД). 
                    try {
                        $DBCmd.Parameters["@db_proc_info"].Value = [int]$itemSession.dbProcInfo
                    }
                    catch {
                        $DBCmd.Parameters["@db_proc_info"].Value = 0
                    }                
                    # Содержит момент времени, когда соединение с СУБД было захвачено данным сеансом последний раз.
                    $DBCmd.Parameters["@db_proc_took_at"].Value = $itemSession.dbProcTookAt.ToString("yyyy-MM-dd HH:mm:ss")
                    # Содержит время соединение с СУБД с момента захвата в миллисекундах.
                    $DBCmd.Parameters["@db_proc_took"].Value = $itemSession.dbProcTook                
                    # Содержит номер сеанса, который является причиной ожидания транзакционной блокировки
                    $DBCmd.Parameters["@blocked_by_dbms"].Value = $itemSession.blockedByDBMS
                    # Содержит номер сеанса, который является причиной ожидания управляемой транзакционной блокировки
                    $DBCmd.Parameters["@blocked_by_ls"].Value = $itemSession.blockedByLS
                    # Содержит интервал времени в миллисекундах, прошедший с момента начала выполнения запроса, в случае, если сеанс выполняет запрос к СУБД.
                    $DBCmd.Parameters["@duration_current_dbms"].Value = $itemSession.durationCurrentDBMS
                    # Содержит суммарное время исполнения запросов к СУБД от имени данного сеанса за последние 5 минут, в миллисекундах.
                    $DBCmd.Parameters["@duration_last_5_min_dbms"].Value = $itemSession.durationLast5MinDBMS
                    # Содержит суммарное время исполнения запросов к СУБД от имени данного сеанса с момента начала сеанса, в миллисекундах.
                    $DBCmd.Parameters["@duration_all_dbms"].Value = $itemSession.durationAllDBMS
                    # Содержит количество данных, переданных и полученных от СУБД от имени данного сеанса за последние 5 минут, в байтах.
                    $DBCmd.Parameters["@dbms_bytes_last_5_min"].Value = $itemSession.dbmsBytesLast5Min
                    # Содержит количество данных, переданных и полученных от СУБД от имени данного сеанса с момента начала сеанса, в байтах.
                    $DBCmd.Parameters["@dbms_bytes_all"].Value = $itemSession.dbmsBytesAll
                    # Содержит интервал времени в миллисекундах, прошедший с момента начала обращения, в случае, если сеанс выполняет обращение к серверу 1С:Предприятия.
                    $DBCmd.Parameters["@duration_current"].Value = $itemSession.durationCurrent
                    # Содержит время исполнения вызовов сервера 1С:Предприятия от имени данного сеанса за последние 5 минут, в миллисекундах.
                    $DBCmd.Parameters["@duration_last_5_min"].Value = $itemSession.durationLast5Min
                    # Содержит время исполнения вызовов сервера 1С:Предприятия от имени данного сеанса с момента начала сеанса, в секундах.
                    $DBCmd.Parameters["@duration_all"].Value = $itemSession.durationAll
                    # Содержит количество вызовов сервера 1С:Предприятия от имени данного сеанса за последние 5 минут.
                    $DBCmd.Parameters["@calls_last_5_min"].Value = $itemSession.callsLast5Min
                    # Содержит количество вызовов сервера 1С:Предприятия от имени данного сеанса с момента начала сеанса.
                    $DBCmd.Parameters["@calls_all"].Value = $itemSession.callsAll
                    # Содержит объем данных, переданных между сервером 1С:Предприятия и клиентским приложением данного сеанса за последние 5 минут, в байтах.
                    $DBCmd.Parameters["@bytes_last_5_min"].Value = $itemSession.bytesLast5Min
                    # Содержит объем данных, переданных между сервером 1С:Предприятия и клиентским приложением данного сеанса с момента начала сеанса, в байтах.
                    $DBCmd.Parameters["@bytes_all"].Value = $itemSession.bytesAll               
                
                    [void]$DBCmd.ExecuteNonQuery()
                }                            
            }
        }

        $COMConnector = $null
        $DBConn = $null
    } 
    catch {
        Write-Host "Ошибка при выполнении скрипта." -ForegroundColor Red;
        Write-Host "Подробно:" -ForegroundColor Red
        Write-Host $Error[0] -ForegroundColor Red
    }

    $COMConnector = $null
    $DBConn = $null
}