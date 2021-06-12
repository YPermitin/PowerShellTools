<#
Пример получения структуры метаданных информационной базы 1С.
Также в скрипте есть пример получения соединений информационной базы из кластера.
#>

function ComProperty ([System.__ComObject]$obj, [string]$value)
{
    $return_value = [System.__ComObject].invokemember($value,[System.Reflection.BindingFlags]::GetProperty,$null,$obj, $null)   
    return $return_value;
}

function ComMethod ([System.__ComObject]$obj, [string]$Method, [Array]$Params)
{
    $return_value = [System.__ComObject].invokemember($Method,[System.Reflection.BindingFlags]::invokeMethod,$null,$obj, $Params)   
    return $return_value;
}

function GetDBStorageStructureInfo([System.__ComObject]$COMConnector, [string]$serverAddress, [string]$infobaseName, [string]$infobaseUser, [string]$infobasePassword)
{
    $ibConnectionString = "Usr=""$infobaseUser"";Pwd=""$infobasePassword"";Srvr=""$serverAddress"";Ref=""$infobaseName""";                        
    $ibConnection = $COMConnector.Connect($ibConnectionString);                        
    $methodResult = ComMethod -obj $ibConnection -Method "ПолучитьСтруктуруХраненияБазыДанных"
    
    $mdObjectList = New-Object System.Collections.ArrayList

    $methodResult | ForEach-Object {
        $mdObject = $_
        $mdObjectName = $null
        $mdObjectMetadataName = $null
        $mdObjectPurpose = $null
        $mdDatabaseObjectName = $null
        $mdFiledsList = New-Object System.Collections.ArrayList
        $mdIndexesList = New-Object System.Collections.ArrayList
        
        $itemIndex = 0
        $mdObject | ForEach-Object {            
            if($itemIndex -eq 0)
            {
                # ИмяТаблицыХранения
                $mdDatabaseObjectName = $_                                    
            } elseif($itemIndex -eq 1)
            {
                # ИмяТаблицы
                $mdObjectName = $_
            } elseif($itemIndex -eq 2)
            {
                # Метаданные
                $mdObjectMetadataName = $_
            } elseif($itemIndex -eq 3)
            {
                # Назначение
                $mdObjectPurpose = $_
            } elseif($itemIndex -eq 4)
            {
                # Поля
                $mdFiledObjectList = $_                                    
                $storageFieldName = ""
                $fieldName = ""
                $metadata = ""
                
                foreach ($mdFiledObject in $mdFiledObjectList) {
                    $itemFieldIndex = 0
                    foreach ($mdFiledObjectItem in $mdFiledObject) {
                        if($itemFieldIndex -eq 0)
                        {
                            $storageFieldName = $mdFiledObjectItem                                                                                          
                        } elseif($itemFieldIndex -eq 1)
                        {
                            $fieldName = $mdFiledObjectItem
                        } elseif($itemFieldIndex -eq 2)
                        {
                            $metadata = $mdFiledObjectItem
                        }
                        $itemFieldIndex = $itemFieldIndex + 1
                    }
                    [void]$mdFiledsList.Add(
                        [PSCustomObject]@{
                            StorageFieldName = [string]$storageFieldName
                            FieldName = [string]$fieldName
                            Metadata = [string]$metadata
                        }
                    );
                }   
            } elseif($itemIndex -eq 5)
            {                                   
                # Индексы
                $mdIndexesObjectList = $_                                    
                foreach ($mdIndexFiled in $mdIndexesObjectList) {
                    $indexItemIndex = 0
                    $mdIndexName = ""
                    $mdIndexFiledList = New-Object System.Collections.ArrayList

                    foreach ($mdIndexFiledItem in $mdIndexFiled) {
                        if($indexItemIndex -eq 0)
                        {                                                
                            $mdIndexName = [string]$mdIndexFiledItem
                        } elseif($indexItemIndex -eq 1)
                        {   
                            foreach ($indexField in $mdIndexFiledItem) {
                                $indexFieldItemIndex = 0
                                $indexStorageFieldName = ""
                                $indexFieldName = ""
                                $indexMetadata = ""
                                foreach ($indexFieldItem in $indexField)
                                {                                                        
                                    if($indexFieldItemIndex -eq 0)
                                    {
                                        $indexStorageFieldName = [string]$indexFieldItem
                                    } elseif($indexFieldItemIndex -eq 1)
                                    {
                                        $indexFieldName = [string]$indexFieldItem
                                    } elseif($indexFieldItemIndex -eq 2)
                                    {
                                        $indexMetadata = [string]$indexFieldItem
                                    }
                                    $indexFieldItemIndex = $indexFieldItemIndex + 1
                                }

                                [void]$mdIndexFiledList.Add(
                                    [PSCustomObject]@{
                                        StorageFieldName = [string]$indexStorageFieldName
                                        FieldName = [string]$indexFieldName
                                        Metadata = [string]$indexMetadata
                                    }
                                );
                            }
                        }

                        $indexItemIndex = $indexItemIndex + 1
                    }

                    [void]$mdIndexesList.Add(
                        [PSCustomObject]@{
                            Name = $mdIndexName
                            Fields = $mdIndexFiledList
                        }
                    );
                }
            }

            $itemIndex = $itemIndex + 1
        }
        
        $metadataObject = [PSCustomObject]@{
            DBName = $mdDatabaseObjectName
            Name = $mdObjectName
            Metadata = $mdObjectMetadataName
            Purpose = $mdObjectPurpose
            Filds = $mdFiledsList
            Indexes = $mdIndexesList
        }
        [void]$mdObjectList.Add($metadataObject)        
    }

    Return $mdObjectList
}

$server1CSettings = @()
$server1CSettings += New-Object PSCustomObject -Property @{
    agentPort = 1540 # Порт сервера 1С
    agentAddress = "localhost" # Адрес сервера 1С
    clusterAdminName = "" # Имя администратора кластера (пустой, если его нет)
    clusterAdminPassword = "" # Пароль администратора кластера (пустой, если его нет)
    infobaseName = "" # Имя информационной базы 1С
    infobaseUser = "ПользовательСАдминистративнымиПравами" # Пользователь 1С для подключения
    infobasePassword = "" # Пароль пользователя
} # Сервер 1С для сбора данных
# Добавляем другие сервера 1С при необходимости

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

    $agentAddress = $_.agentAddress
    $agentPort = $_.agentPort
    $clusterAdminName = $_.clusterAdminName
    $clusterAdminPassword = $_.clusterAdminPassword
    $infobaseName = $_.infobaseName
    $infobaseUser = $_.infobaseUser
    $infobasePassword = $_.infobasePassword
    $fullAgentAddress = "tcp://" + $agentAddress + ":" + $agentPort;

    $serverAgent = $COMConnector.ConnectAgent($fullAgentAddress);
    $clusterList = $ServerAgent.GetClusters();
    foreach ($cluster in $clusterList) {
        $serverAgent.Authenticate($Cluster, $clusterAdminName, $clusterAdminPassword)  
        $workingProcesses = $serverAgent.GetWorkingProcesses($cluster);
        foreach ($workingProcess in $workingProcesses) {
            # Подключаемся к первому активному процессу
            if($workingProcess.Enable -and $workingProcess.Running -eq 1)
            {
                $workingProcessHostName = $workingProcess.HostName
                $workingProcessPort = $workingProcess.MainPort
                $workingProcessConnectionString = "tcp://" + $workingProcessHostName + ":" + $workingProcessPort
                $workingProcessConnection = $COMConnector.ConnectWorkingProcess($workingProcessConnectionString)
                $workingProcessConnection.AuthenticateAdmin($clusterAdminName, $clusterAdminPassword)
                $infobases = $workingProcessConnection.GetInfoBases()
                $infobases | ForEach-Object {
                    $infobase = $_     
                    if($infobase.Name -eq $infobaseName)
                    {
                        <#
                        Получение информации о соединениях конкретной информационной базы
                        $workingProcessConnection.AddAuthentication($infobaseUser,$infobasePassword)                        
                        $infobaseConnections = $workingProcessConnection.GetInfoBaseConnections($infobase)
                        $infobaseConnections | ForEach-Object {
                            $infobaseConnection = $_   
                            $infobaseConnection.AppID
                            $infobaseConnection.ConnID
                            $infobaseConnection.userName
                        }
                        #>

                        $metadataObjects = GetDBStorageStructureInfo $COMConnector $agentAddress $infobaseName $infobaseUser $infobasePassword
                        <#
                        Пример вывода
                        DBName   : ScheduledJobs28571
                        Name     :
                        Metadata : РегламентноеЗадание.ОтправкаЭлектронныхДокументов
                        Purpose  : РегламентныеЗадания
                        Filds    : {@{StorageFieldName=ID; FieldName=; Metadata=}, @{StorageFieldName=Description; FieldName=; Metadata=}, @{StorageFieldName=JobKey; FieldName=; Metadata=}, @{StorageFieldName=Meta 
                                dataID; FieldName=; Metadata=}…}
                        Indexes  : {@{Name=ByID; Fields=System.Collections.ArrayList}}
                        #>
                        $metadataObjects | ForEach-Object {
                            $_.DBName # Имя объекта базы данных
                            $_.Name # Имя объекта
                            $_.Purpose # Назначение
                            $_.Filds | ForEach-Object { # Поля таблицы
                                $_.StorageFieldName # Имя поля в базе данных
                                $_.FieldName # Имя поля
                                $_.Metadata # Имя метаданных
                            }
                            $_.Indexes | ForEach-Object { # Список индексов таблицы
                                $_.Name # Имя индекса
                                $_.Fields | ForEach-Object { # Список полей индекса
                                    $_.StorageFieldName # Имя поля в базе данных
                                    $_.FieldName # Имя поля
                                    $_.Metadata # Имя метаданных
                                }
                            }
                        }
                    }
                }
                break
            }
        }
    }
}