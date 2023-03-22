<#
Скрипт для скачивания текущей конфигурации устройства.
Например, для целей бэкапирования.

Подробнее: https://wiki.mikrotik.com/wiki/Manual:System/Backup

#>

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

function ExecuteCommandOnMikroTik {
    param ($sessionId, $command)

    $result = Invoke-SSHCommand -SessionId $sessionId -Command $command
    $result
}

function DisconnectMikroTik {
    param ($sessionId)
    $removed = Remove-SSHSession -SessionId $sessionId
    if($removed -eq $true)
    {
        Write-Host "Выполнено отключение от устройства MikroTik (сессия $sessionId)."
    }
}

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

$MikroTikUser = "admin"
$MikroTikPass = $(ConvertTo-SecureString "<MyPassword>" -AsPlainText -Force)
$MikroTikIP = "192.168.88.1"
$MikroTikPort = 22

$sessionId = ConnectToMikroTik $MikroTikIP $MikroTikUser $MikroTikPass $MikroTikPort

$backupFileName = "mikrotik_backup_pwsh"
$result = ExecuteCommandOnMikroTik $sessionId "/system backup save name=$backupFileName"
foreach($outputLine in $result.Output)
{
    Write-Host $outputLine
}

$downloadedFilePath = DownloadFile $MikroTikIP $MikroTikUser $MikroTikPass "$backupFileName.backup" $MikroTikPort
Write-Host "Загруженный файл конфигурации: $downloadedFilePath"

DisconnectMikroTik $sessionId