$operationDate = Get-Date
$domainInfo = Get-ADDomain
$domainInfoName = $domainInfo.Forest
$listAccounts = New-Object System.Collections.ArrayList

# Добавляем учетные записи из группы
$ouDevelopers = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName |
    Where-Object { $_.CanonicalName -like "*My Super Department*" } | 
    Select-Object -Property CanonicalName, DistinguishedName
$ouDevelopers | ForEach-Object {
    $ouUsers = Get-ADUser -SearchBase $_.DistinguishedName -filter * -properties *

    $ouUsers | ForEach-Object {
        $listAccounts.Add($_)
    } | Out-Null 
}

# Добавляем конкретную учетную запись по логину
Get-ADUser -Identity ypermitin | ForEach-Object {
        $listDevelopers.Add($_)
} | Out-Null

# Добавляем конкретную учетную запись по имени
Get-AdUser -Filter "name -eq 'Пермитин Юрий'" | ForEach-Object {
        $listDevelopers.Add($_)
} | Out-Null

# Для 8.2 использовать "V82.COMConnector"
$COMConnector = New-Object -COMObject "V83.COMConnector"
if($null -ne $COMConnector) {    
    $agentPort = $clusterPort;
    $agentAddress = "localhost";
    $clusterAdminName = ""; # Имя администратора кластера
    $clusterAdminPassword = ""; # Пароль администратора кластера
    $fullAgentAddress = "tcp://" + $agentAddress + ":" + $agentPort;
    $serverAgent = $COMConnector.ConnectAgent($fullAgentAddress)
    $serverAgent.AuthenticateAgent($clusterAdminName, $clusterAdminPassword)

    $agentAdmins = $serverAgent.GetAgentAdmins();
    
    # Создаем пользователей или обновляем существующих
    $listDevelopers | ForEach-Object {
        $userName = $_.Name
        $userNameDomain = $_.SamAccountName
        $sysUserName = "\\$domainInfoName\$userNameDomain".ToLower()
        $foundUser = $agentAdmins | Where-Object { $_.Name -eq $userName };

        if($foundUser -ne $null -and $foundUser.SysUserName.ToLower() -eq $sysUserName.ToLower())
        {
            Write-Host "Администратор уже существует: $sysUserName" -BackgroundColor Blue            
        } else
        {
            if($foundUser -eq $null)
            {
                $newRegAdmin = $serverAgent.CreateClusterAdminInfo()
                $newRegAdmin.Name = $userName
                $newRegAdmin.Descr = "Создан автоматически ($operationDate)"
                $newRegAdmin.SysAuthAllowed = $true            
                $newRegAdmin.SysUserName = $sysUserName;
                $serverAgent.RegAgentAdmin($newRegAdmin)
            Write-Host "Добавлен администратор: $sysUserName" -BackgroundColor Green
            } else
            {
                $newRegAdmin = $foundUser
                $newRegAdmin.Descr = "Обновлен автоматически ($operationDate)"
                $newRegAdmin.SysAuthAllowed = $true            
                $newRegAdmin.SysUserName = $sysUserName;
                $serverAgent.RegAgentAdmin($newRegAdmin)
                Write-Host "Обновлен администратор: $sysUserName" -BackgroundColor Green
            }                                    
        }
    }

    # Удаляем устаревшие учетные записи
    $agentAdmins = $serverAgent.GetAgentAdmins();
    $agentAdmins | ForEach-Object {
        $agentUser = $_
        # Только те, у которых установлена аутентификация через домен
        if($agentUser.SysAuthAllowed -eq $true)
        {
            $agentUserAdmin = $_.Name
            $agentUserSysname = $_.SysUserName
            $foundUser = $listDevelopers | Where-Object { $_.Name -eq $agentUserAdmin }
            if($foundUser -eq $null)
            {
                $serverAgent.UnregAgentAdmin($agentUserAdmin)                
                Write-Host "Удален администратор: $agentUserSysname" -BackgroundColor Red
            }
        }
    }
}