$services1C = Get-WmiObject win32_service | ?{$_.Name -like '*'} |
    Select Name, DisplayName, State, PathName | 
    Where-Object { $_.PathName  -Like "*ragent.exe*" };

$obj = [PSCustomObject] @{
    data = @($services1C | % {
        $serviceInfo = $_;

        if($serviceInfo.State -eq 'Running')
        {
            $serviceName = $serviceInfo.Name;
            try
            {
                Stop-Service $serviceName;
                Write-Host "Остановлена служба ""$serviceName""" -ForegroundColor Green
            } catch
            {
                Write-Host "Ошибка при остановке службы ""$serviceName""" -ForegroundColor Red
                Write-Host "Подробно:" -ForegroundColor Red
                Write-Host $Error[0] -ForegroundColor Red
            }
        }        
    }) 
}