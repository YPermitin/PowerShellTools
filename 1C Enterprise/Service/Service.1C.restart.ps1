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
                Restart-Service $serviceName;
                Write-Host "Перезапущена служба ""$serviceName""" -ForegroundColor Green
            } catch
            {
                Write-Host "Ошибка при перезапуске службы ""$serviceName""" -ForegroundColor Red
                Write-Host "Подробно:" -ForegroundColor Red
                Write-Host $Error[0] -ForegroundColor Red
            }
        }        
    }) 
}