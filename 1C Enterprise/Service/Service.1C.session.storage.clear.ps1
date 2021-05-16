<#
Очистка сеансовых данных 1С
#>

$services1C = Get-WmiObject win32_service | ? { $_.Name -like '*' } |
Select Name, DisplayName, State, PathName | 
Where-Object { $_.PathName -Like "*ragent.exe*" };

$services1C | % {
    $serviceInfo = $_
    $serviceName = $serviceInfo.Name

    # 1. Останавливаем службу 1С
    Write-Host "Stop service 1C: $serviceName" -BackgroundColor Blue
    Stop-Service -Name $serviceName -NoWait
    $svc = Get-Service $serviceName
    Write-Host $svc.Status
    $svc.WaitForStatus('Stopped')
    Write-Host $svc.Status
    # Дополнительное ожидание для освобождения файлов процессами после остановки службы
    Start-Sleep 15

    # 2. Ищем путь к каталогу с сеансовыми данными
    $serviceExecPath = $serviceInfo.PathName
    $hash = [ordered]@{}
    $serviceExecPath.Split("-").Trim() | Where-Object { $_.Contains(" ") } | ForEach-Object { 
        $name, $value = $_ -split '\s+', 2
        $hash[$name] = $value
    }
    $clusterPath = $hash.d -replace '"', ''
    $clusterRegPort = $hash.regport
    $clusterRegDirectory = Join-Path -Path $clusterPath -ChildPath "reg_$clusterRegPort"            
    $storageSessionDataSizeMb = 0
    Get-ChildItem $clusterRegDirectory | 
    Where-Object { $_.Name -like "snccntx*" } |
    ForEach-Object {
        $storageSessionDataPath = Join-Path -Path $clusterRegDirectory -ChildPath $_

        # 3. Удаляем каталоги с сеансовыми данными
        Write-Host "Remove session storage directory: $storageSessionDataPath" -BackgroundColor Blue
        Remove-Item -LiteralPath $storageSessionDataPath -Force -Recurse
    }

    # 4. Запускаем службу 1С
    Write-Host "Start service 1C: $serviceName" -BackgroundColor Blue
    Start-Service -Name $serviceName
}
