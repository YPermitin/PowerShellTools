$allServices1C = Get-WmiObject win32_service | ?{$_.Name -like '*'} |
    Select Name, DisplayName, State, PathName | 
    Where-Object { $_.PathName  -Like "*ragent.exe*" };

$allServices1C | % {

    $services1C = $_;
    $serviceExecPathRagent = $services1C.PathName.split('"')[1];
    $serviceDirectory = [System.IO.Path]::GetDirectoryName($serviceExecPathRagent);
    $comcntrPath = "$serviceDirectory\comcntr.dll";
    $regCommand = "regsvr32.exe /u ""$comcntrPath""";
    $platformVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($serviceExecPathRagent).FileVersion

    Write-Host "Начало отмены регистрации COM-компоненты 1С:Предприятия";
    Write-Host "Версия платформы: $platformVersion";
    Write-Host "Путь к DLL: ""$comcntrPath""";
    Write-Host "Команда регистрации компоненты: ""$regCommand""";

    try
    {
        cmd /c "$regCommand"
        Write-Host "Отмена регистрации компоненты успешно выполнена!" -ForegroundColor Green
    } catch
    {
        Write-Host "Ошибка при отмене регистрации компоненты!" -ForegroundColor Red
        Write-Host "Подробно:" -ForegroundColor Red
        Write-Host $Error[0] -ForegroundColor Red
    }
}