<#
Скрипт получает информацию о текущих подключенных хостах.
Для получения информации используются данные DHCP-сервера в части выданных адресов и времени с последней выдачи адреса хосту.

Подробнее: https://wiki.mikrotik.com/wiki/Manual:IP/DHCP_Server#Leases

Пример вывода:

hostName             address        macAddress        lastSeen
--------             -------        ----------        --------
"Yandex-Station-Max" 192.168.88.186 B8:87:6E:03:03:B2 3m57s
"yandex-mini2"       192.168.88.15  B8:87:6E:1F:84:B3 4m7s
"DC"                 192.168.88.21  00:0C:29:B5:00:52 1m19s
"Galaxy-Note"        192.168.88.10  04:D6:AA:2D:24:6C 2m53s
"DESKTOP-1DK6Q3R"    192.168.88.25  00:0C:29:28:C3:B6 2m

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

$result = ExecuteCommandOnMikroTik $sessionId "/ip dhcp-server lease print detail where status=""bound"" and last-seen<600"

$activeClients = New-Object Collections.Generic.List[object]
$currentItemContent = ""
foreach($outputLine in $result.Output)
{
    $outputLine = $outputLine.Trim()
    if($outputLine.StartsWith("Flags"))
    {
        continue
    }

    $currentItemContent = $currentItemContent + $outputLine + " "
    if([string]::IsNullOrEmpty($outputLine))
    {    
        $contentStartIndex = $currentItemContent.IndexOf("address=")
        if($contentStartIndex -gt 0)
        {
            $currentItemContent = $currentItemContent.Substring($contentStartIndex, $currentItemContent.Length - $contentStartIndex)

            $currentItemKeyAndValues = $currentItemContent.Split(" ")

            $activeClientInfo = [PSCustomObject]@{
                address = ""
                macAddress = ""
                clientId = ""
                addressLists = ""
                server = ""
                dhcpOption = ""
                status = ""
                expiresAfter = ""
                lastSeen = ""
                activeClientId = ""
                activeServer = ""
                hostName = ""
            }
            foreach($currentKeyAndValue in $currentItemKeyAndValues)
            {
                $keyAndValue = $currentKeyAndValue.Split("=")
                if($keyAndValue.Count -eq 2)
                {
                    $itemName = $keyAndValue[0]
                    $itemValue = $keyAndValue[1]

                    if($itemName -eq "address")
                    {
                        $activeClientInfo.address = $itemValue
                    } elseif($itemName -eq "mac-address")
                    {
                        $activeClientInfo.macAddress = $itemValue
                    } elseif($itemName -eq "client-id")
                    {
                        $activeClientInfo.clientId = $itemValue
                    } elseif($itemName -eq "address-lists")
                    {
                        $activeClientInfo.addressLists = $itemValue
                    } elseif($itemName -eq "server")
                    {
                        $activeClientInfo.server = $itemValue
                    } elseif($itemName -eq "dhcp-option")
                    {
                        $activeClientInfo.dhcpOption = $itemValue
                    } elseif($itemName -eq "status")
                    {
                        $activeClientInfo.status = $itemValue
                    } elseif($itemName -eq "expires-after")
                    {
                        $activeClientInfo.expiresAfter = $itemValue
                    } elseif($itemName -eq "last-seen")
                    {
                        $activeClientInfo.lastSeen = $itemValue
                    } elseif($itemName -eq "active-client-id")
                    {
                        $activeClientInfo.activeClientId = $itemValue
                    } elseif($itemName -eq "active-server")
                    {
                        $activeClientInfo.activeServer = $itemValue
                    } elseif($itemName -eq "host-name")
                    {
                        $activeClientInfo.hostName = $itemValue
                    }
                }
            }

            $activeClients.Add($activeClientInfo)
        }
        $currentItemContent = ""
    }
}

DisconnectMikroTik $sessionId

$activeClients | Select-Object hostName, address, macAddress, lastSeen