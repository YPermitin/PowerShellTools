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
                                                
                        # Второй параметр - режим удаления информационной базы:
                        #    0 - при удалении информационной базы базу данных не удалять;
                        #    1 - при удалении информационной базы удалить базу данных;
                        #    2 - при удалении информационной базы очистить базу данных.
                        $workProcessConnection.DropInfoBase($itemInfobase, 0);
                        
                        $infobaseName = $itemInfobase.Name

                        Write-Host "Удалена информационная база $infobaseName" -ForegroundColor Green                        
                        
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