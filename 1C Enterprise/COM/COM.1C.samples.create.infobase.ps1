$services1C = Get-WmiObject win32_service | ?{$_.Name -like '*'} |
    Select Name, DisplayName, State, PathName | 
    Where-Object { $_.PathName  -Like "*ragent.exe*" };

$services1C | % {
    $serviceInfo = $_;
    $serviceExecPath = $services1C.PathName;
    $serviceExecPathRagent = $services1C.PathName.split('"')[1]

    $hash = [ordered]@{}
    $serviceExecPath.Split("-").Trim() | Where-Object { $_.Contains(" ") } | ForEach-Object { 
        $name, $value = $_ -split '\s+', 2
        $hash[$name] = $value
    }

    if([System.IO.File]::Exists($serviceExecPathRagent) -ne $true)
    {        
        break
    }
    
    $platformVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($serviceExecPathRagent).FileVersion        
    $clusterPath = $hash.d -replace '"', ''
    $clusterRegPort = $hash.regport
    $clusterPort = $hash.port
    $clusterPortRange = $hash.range
    $clusterRegPath = "$clusterPath\reg_$clusterRegPort"

    $agentPort = $clusterPort;
    $agentAddress = "localhost";
    $clusterAdminName = ""; # Имя администратора кластера
    $clusterAdminPassword = ""; # Пароль администратора кластера
    $fullAgentAddress = "tcp://" + $agentAddress + ":" + $agentPort;

    $COMConnector = $null;
    try {
        if($platformVersion -like "8.2.*")
        {            
            $COMConnector = New-Object -COMObject "V82.COMConnector"
        }
        if($platformVersion -like "8.3.*")
        {
            $COMConnector = New-Object -COMObject "V83.COMConnector"
        }

        if($null -ne $COMConnector) {
            $serverAgent = $COMConnector.ConnectAgent($SrvAddr);
            $clusterList = $ServerAgent.GetClusters();
            foreach ($cluster in $clusterList) {
                $serverAgent.Authenticate($Cluster, $clusterAdminName, $clusterAdminPassword)                   
                
                $workingProcesses = $serverAgent.GetWorkingProcesses($cluster)
                foreach ($workProcess in $workingProcesses) {
                    if($workProcess.Running -ne 1)
                    {
                        continue
                    }

                    $workProcessConnectionString = "tcp://"+$workProcess.HostName+":"+$workProcess.MainPort
                    $workProcessConnection= $COMConnector.ConnectWorkingProcess($workProcessConnectionString)

                    $newInfobase = $workProcessConnection.CreateInfoBaseInfo();
                    # Имя информационной базы и описание
                    $newInfobase.Name = "<Имя информационной базы на сервере 1С>"
                    $newInfobase.Descr = "Произвольное описание"
                    # Смещение дат в информационной базе (0 или 2000).
                    $newInfobase.DateOffset = 2000;
                    # Определяет тип СУБД, в которой размещается информационная база. Возможны следующие типы СУБД:
                    #  MSSQLServer - Microsoft SQL Server;
                    #  PostgreSQL - PostgreSQL;
                    #  IBMDB2 - IBM DB2;
                    #  OracleDatabase - Oracle Database.
                    $newInfobase.DBMS = "MSSQLServer";
                    # Параметры подключения к базе данных
                    $newInfobase.DBName = "<Имя базы данных>"
                    $newInfobase.DBServerName = "<Имя сервера базы данных или адрес>"
                    $newInfobase.DBUser = "<Пользователь базы данных>"
                    $newInfobase.DBPassword = "<Пароль пользователя базы данных>"            
                    # Идентификатор национальных настроек информационной базы, например, ru_RU для России.
                    $newInfobase.Locale = "ru_RU"
                    
                    # Второй параметр - режим создания информационной базы:
                    #  0 - при создании информационной базы базу данных не создавать;
                    #  1 - при создании информационной базы создавать базу данных.                         
                    $workProcessConnection.CreateInfoBase($newInfobase, 0);

                    $infobaseName = $newInfobase.Name
                    Write-Host "Создана информационная база $infobaseName" -ForegroundColor Green
                                        
                    break
                }
            }
        }

        $COMConnector = $null
    } 
    catch {
        Write-Host "Ошибка при выполнении скрипта." -ForegroundColor Red;
        Write-Host "Подробно:" -ForegroundColor Red
        Write-Host $Error[0] -ForegroundColor Red
    }
}