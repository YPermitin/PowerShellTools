<#
Скрипт получает информацию об использовании ресурсов и статистику маршрутизатора, 
такую как время безотказной работы, использование памяти, использование диска, версия и т.д.

Подробнее: https://wiki.mikrotik.com/wiki/Manual:System/Resource

Пример вывода:

Name              Value
----              -----
uptime            1w23h15m8s
version           6.49.7 (stable)
factory-software  6.44.6
free-memory       935.5MiB
total-memory      1024.0MiB
cpu               ARMv7
cpu-count         4
cpu-frequency     1400MHz
cpu-load          0%
free-hdd-space    422.8MiB
total-hdd-space   512.3MiB
architecture-name arm
board-name        RB4011iGS+5HacQ2HnD
platform          MikroTik

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

$MikroTikUser = "admin"
$MikroTikPass = $(ConvertTo-SecureString "<MyPassword>" -AsPlainText -Force)
$MikroTikIP = "192.168.88.1"
$MikroTikPort = 22

$sessionId = ConnectToMikroTik $MikroTikIP $MikroTikUser $MikroTikPass $MikroTikPort

$healthInfo = New-Object Collections.Generic.List[object]
$result = ExecuteCommandOnMikroTik $sessionId "/system resource print"
foreach($outputLine in $result.Output)
{
    $lineValues = $outputLine.Split(":")    
    if($lineValues.Count -eq 2)
    {
        $healthInfo.Add(
            [PSCustomObject]@{
                Name = $lineValues[0].Trim()
                Value = $lineValues[1].Trim()
            }
        )
    }
}

DisconnectMikroTik $sessionId

$healthInfo