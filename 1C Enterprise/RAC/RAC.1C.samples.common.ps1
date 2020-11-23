# Параметры
$platformVersion = "8.3.18.1208"
$racExecPath = "C:\Program Files\1cv8\" + $platformVersion + "\bin\rac.exe"

# Получаем список кластеров
$commandClusterInfoResult = Execute-Command -commandTitle "Clusters List" -commandPath $racExecPath -commandArguments " cluster list"
$commandClusterInfoResultAsObjectList = Convert-StdOut-ToObjectList($commandClusterInfoResult[0].stdout.ToString());
$commandClusterInfoResultAsObjectList | ForEach-Object {
    $clusterObject = $_
    if($clusterObject -eq $null)
    {
        continue
    }  

    # Получаем список информационных баз
    $clusterId = $clusterObject.cluster
    $commandInfobasesInfoArguments = " infobase summary list --cluster=" + $clusterId
    $commandInfobasesInfo = Execute-Command -commandTitle "Infobases List" -commandPath $racExecPath -commandArguments $commandInfobasesInfoArguments
    $commandInfobasesInfoAsObjectList = Convert-StdOut-ToObjectList($commandInfobasesInfo[0].stdout.ToString());

    $commandInfobasesInfoAsObjectList | ForEach-Object {
        $itemInfoBase = $_
        if($itemInfoBase -eq $null)
        {
            continue
        } 

        # Изменяем параметры информационной базы
        $infobaseId = $itemInfoBase.infobase
        $userName = """"""; # Имя пользователя информационной базы
        $userPassword = """"""; # Пароль пользователя информационной базы
        $commandInfobasesDisableJobs = " infobase update --cluster=" + $clusterId + " --infobase=" + $infobaseId + "  --infobase-user=" + $userName + "  --infobase-pwd=" + $userPassword + " --scheduled-jobs-deny=on"        
        $commandInfobasesInfo = Execute-Command -commandTitle "Infobases Scheduled Jobs Deny" -commandPath $racExecPath -commandArguments $commandInfobasesDisableJobs

        $infobaseName = $itemInfoBase.name
        Write-Host "Изменены настройки для базы $infobaseName" -ForegroundColor Green
    }
}

<#
Служебные функции
#>

# Функция для выполнения произвольной команды с аргументами
Function Execute-Command ($commandTitle, $commandPath, $commandArguments)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $pinfo.Arguments = $commandArguments

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit(100) | Out-Null
    
    $resultObject = [pscustomobject]@{
        commandTitle = $commandTitle
        stdout = $p.StandardOutput.ReadToEnd()
        stderr = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode
    }

    return $resultObject
}
Function Convert-StdOut-ToObjectList($sourceResult)
{
    $collectionResult = New-Object System.Collections.ArrayList
    $paramsResult = $sourceResult -split [System.Environment]::NewLine

    $resultObject = $null
    
    $paramsResult | ForEach-Object {
        $paramResult = $_;
        $indexDelimeter = $paramResult.IndexOf(":");
        if($indexDelimeter -gt 0)
        {
            if($null -eq $resultObject)
            {
                $resultObject = New-Object -TypeName PSObject
            }

            $paramName = $paramResult.Substring(0, $indexDelimeter).Trim();        
            $paramValue = $paramResult.Substring($indexDelimeter + 1, $paramResult.Length - $indexDelimeter - 1).Trim();       
            if($null -ne $paramName -and $null -ne $paramValue)
            {
                $resultObject | Add-Member -MemberType NoteProperty -Name $paramName -Value $paramValue
            }
        } else
        {
            $collectionResult.Add($resultObject) | Out-Null;
            $resultObject = $null
        }
    }        

    return $collectionResult;
}