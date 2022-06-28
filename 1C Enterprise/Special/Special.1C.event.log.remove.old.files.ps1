<#
Удаление устаревших файлов журнала регистрации 1С. Только для текстового формата.
#>

$limit = (Get-Date).AddDays(-15) # Файлы старше 15 дней
$services1C = Get-WmiObject win32_service | ?{$_.Name -like '*'} |
    Select Name, DisplayName, State, PathName | 
    Where-Object { $_.PathName  -Like "*ragent.exe*" };

$services1C | % {
    $serviceExecPath = $_.PathName;

    $hash = [ordered]@{}
    $serviceExecPath.Split("-").Trim() | Where-Object { $_.Contains(" ") } | ForEach-Object { 
        $name, $value = $_ -split '\s+', 2
        $hash[$name] = $value
    }

    $clusterPath = $hash.d -replace '"', ''
    $clusterRegPort = $hash.regport
    $clusterRegPath = "$clusterPath\reg_$clusterRegPort"
    $clusterConfigFile = "$clusterRegPath\1CV8Reg.lst"
    $clusterConfigFileExists = Test-Path $clusterConfigFile -PathType Leaf
    if($clusterConfigFileExists -eq $false)
    {
        $clusterConfigFile = "$clusterRegPath\1CV8Clst.lst"
    }
    $clusterConfigFileExists = Test-Path $clusterConfigFile -PathType Leaf
    if($clusterConfigFileExists -eq $true)
    {
        Select-String -Path $clusterConfigFile '\{[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12},\"[A-Za-z0-9-_]+\"' -AllMatches | 
        Foreach-Object {$_.Matches} | 
        ForEach-Object {
            $parsedString = $_.Value -split ","
            $ibGuid = $parsedString[0] -replace "{", "" 
            $ibName = $parsedString[1] -replace '"', ""
            
            # Фильтр по имени базы. По умолчанию все базы
            if($ibName -like "*")
            {
                $eventLogPath = "$clusterRegPath\$ibGuid\1Cv8Log"
                $eventLogPathExists = Test-Path $eventLogPath -PathType Container
                if($eventLogPathExists -eq $true)
                {
                    Write-Host "Infobase for clearing event log: $ibName"
                    Write-Host "Event log path: $eventLogPath"            
        
                    $logFilesData = Get-ChildItem -Path $eventLogPath *.lgp -Force | 
                    Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } 
                    Write-Host "Log files to remove:"
                    $logFilesData                    
                    $logFilesData | Remove-Item -Force

                    $logFilesIndexes = Get-ChildItem -Path $eventLogPath *.lgx -Force | 
                    Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } 
                    Write-Host "Log indexes files to remove:"
                    $logFilesIndexes                    
                    $logFilesIndexes | Remove-Item -Force
                }
            }
        }
    } else
    {
        Write-Host "Cluster config file not found: $clusterConfigFile"
    }
}
