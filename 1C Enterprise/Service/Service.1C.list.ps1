$services1C = Get-WmiObject win32_service | ?{$_.Name -like '*'} |
    Select Name, DisplayName, State, PathName | 
    Where-Object { $_.PathName  -Like "*ragent.exe*" };

$obj = [PSCustomObject] @{
    data = @($services1C | % {
        $serviceInfo = $_;
        [PSCustomObject] @{
            'Name' = $serviceInfo.Name
            'DisplayName' = $serviceInfo.DisplayName
            'PathName' = $serviceInfo.PathName
            'State' = $serviceInfo.State
        }
    }) 
}

$obj.data | Format-Table