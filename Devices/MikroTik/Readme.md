# MikroTik

Управление устройствами компании [MikroTik](https://mikrotik.com/products) на базе [RouterOS](https://mikrotik.com/download).

## Принцип работы скриптов

Все скрипты взаимодействуют с устройствами MikroTik по средствам SSH (SFTP в том числе). Для этого добавлены следующие функции.

```pwsh
# Установка соединения с устройством
function ConnectToMikroTik {
    param ($address, $userName, [SecureString] $password, $port = 22)
   
    Import-Module Microsoft.PowerShell.Utility

    if (Get-Module -ListAvailable -Name Posh-Ssh) {
        Import-Module Posh-Ssh 
    }
    else {
        Install-Module Posh-Ssh -Force
        Import-Module Posh-Ssh
    }

    $credential = New-Object System.Management.Automation.PSCredential ($userName, $password)
    $currentSession = New-SSHSession -ComputerName $address -Port $port -Credential $credential -AcceptKey
    
    if($currentSession.Connected -eq $true)
    {
        Write-Host "Выполнено подключение к устройству MikroTik по адресу ""$address"" от имени пользователя ""$userName"" (сеанс $($currentSession.SessionId))..."
    } else {
        throw "Ошибка подключения к устройству MikroTik по адресу ""$address"" от имени пользователя ""$userName"": $($_)"
    }

    $currentSession.SessionId
}

# Выполнение произвольной команды на устройстве
function ExecuteCommandOnMikroTik {
    param ($sessionId, $command)

    $result = Invoke-SSHCommand -SessionId $sessionId -Command $command
    $result
}

# Завершение соединения с устройством
function DisconnectMikroTik {
    param ($sessionId)
    $removed = Remove-SSHSession -SessionId $sessionId
    if($removed -eq $true)
    {
        Write-Host "Выполнено отключение от устройства MikroTik (сессия $sessionId)."
    }
}

# Загрузка файла с устройства
function DownloadFile{
    param ($address, $userName, [SecureString] $password, $filePath, $port = 22)

    $credential = New-Object System.Management.Automation.PSCredential ($userName, $password)
    $currentSession = New-SFTPSession -ComputerName $address -Credential $credential -Port $port
    if($currentSession.Connected -eq $true)
    {
        Write-Host "Выполнено подключение (SFTP для передачи файлов) к устройству MikroTik по адресу ""$address"" от имени пользователя ""$userName"" (сеанс $($currentSession.SessionId))..."
    } else {
        throw "Ошибка подключения (SFTP для передачи файлов) к устройству MikroTik по адресу ""$address"" от имени пользователя ""$userName"": $($_)"
    }

    Write-Host "Начало загрузки файла..."
    $tmpPath = [System.IO.Path]::GetTempPath()
    Get-SFTPItem -SessionId $currentSession.SessionId -Path $filePath -Destination $tmpPath -Force
    Remove-SFTPSession -SessionId $sessionId
    Write-Host "Выполнено отключение (SFTP для передачи файлов) от устройства MikroTik (сессия $sessionId)."

    $downloadedFilePath = $([System.IO.Path]::Combine($tmpPath, $filePath));
    if(Test-Path $downloadedFilePath)
    {
        Write-Host "Завершение загрузки файла."
        Write-Host "Загруженный файл: $downloadedFilePath"
    } else {
        throw "Не удалось загрузить файл конфигурации: $_"
    }

    $downloadedFilePath
}
```

Примеры использования можно посмотреть в скриптах раздела. Ниже самый простой пример.

```pwsh
# Подключаемся
$sessionId = ConnectToMikroTik $MikroTikIP $MikroTikUser $MikroTikPass $MikroTikPort

# Отправка команды
$result = ExecuteCommandOnMikroTik $sessionId "/system resource print"
$result.Output

# Отключение
DisconnectMikroTik $sessionId
```

## Скрипты

Описание скриптов раздела. Все они выполняют команды через SSH, но в версиях RouterOS 7.1+ появится [REST API](https://help.mikrotik.com/docs/display/ROS/REST+API) для выполнения аналогичных действий.

| Имя скрипта | Описание |
| ----------- | -------- |
| [Get-DeviceInfo](Get-DeviceInfo.ps1) | Скрипт получает информацию об использовании ресурсов и статистику маршрутизатора. |
| [Get-DeviceHealth](Get-DeviceHealth.ps1) | Скрипт для получении информации о состоянии оборудования. |
| [Get-DeviceActiveClients](Get-DeviceActiveClients.ps1) | Скрипт получает информацию о текущих подключенных хостах. |
| [Get-DeviceConfiguration](Get-DeviceConfiguration.ps1) | Скрипт для скачивания текущей конфигурации устройства. |

## Полезные ссылки

* [Официальная документация](https://wiki.mikrotik.com/wiki/Main_Page)
* [Официальная документация Router OS](https://help.mikrotik.com/docs/display/ROS/RouterOS)
* [REST API для RouterOS с версии 7.x](https://help.mikrotik.com/docs/display/ROS/REST+API)
