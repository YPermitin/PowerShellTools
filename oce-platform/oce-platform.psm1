function Get-1CInstances
<#
.Synopsis
   Получение установленных версий платформы
.DESCRIPTION
   Получает список установленных версий платформы 1С:Предприятие
.NOTES  
    Name: oceHelper
    Author: ypermitin@yandex.ru
.LINK  
    https://github.com/YPermitin/PowerShell-For-1C-Developer
.EXAMPLE
   Get-1CInstances "8.3*" | Foreach("DisplayName")
.OUTPUTS
   Коллекцию объектов с описанием установленных версий платформы 1С:Предприятие
#>
{
    Param(
        # Версия платформы для поиска
        [string]$PlatformVersion = "*"
    )
    
    [Array]$RegUnistValues = Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall 
    [Array]$temp = $RegUnistValues | ForEach-object {(Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_)}

    [Array]$result = @();
    for($i=1; $i -le $temp.Length; $i++)
    {
        if((($temp[$i].DisplayName -like '*1c*предприятие*') -Or ($temp[$i].DisplayName -like '*1c*enterprise*')) -and $temp[$i].DisplayVersion -like $PlatformVersion)
        {
            $result += $temp[$i];
        }
    }

    Remove-Variable temp;

    $result
}

function Get-1CEstart
<#
.Synopsis
   Поиск единого стартера платформы 1С:Предприятие
.DESCRIPTION
   Поиск единого стартера платформы 1С:Предприятие для всех установленных версий в виде запускаемого приложения 1cestart.exe
.NOTES  
    Name: oceHelper
    Author: ypermitin@yandex.ru
.LINK  
    https://github.com/YPermitin/PowerShell-For-1C-Developer
.EXAMPLE
   & (Get-1CEstart)
.OUTPUTS
   Полный путь к исполняемому файлу 1cestart.exe
#>
{
    Param(
    )
    
    $starterPath = $null

    $regKeys = @( @{ leaf='ClassesRoot'; path='Applications\\1cestart.exe\\shell\\open\\command' } )
    $regKeys += @{ leaf='ClassesRoot'; path='V83.InfoBaseList\\shell\\open\\command' }
    $regKeys += @{ leaf='ClassesRoot'; path='V83.InfoBaseListLink\\shell\\open\\command' }
    $regKeys += @{ leaf='ClassesRoot'; path='V82.InfoBaseList\\shell\\open\\command' }
    $regKeys += @{ leaf='LocalMachine'; path='SOFTWARE\\Classes\\Applications\\1cestart.exe\\shell\\open\\command' }
    $regKeys += @{ leaf='LocalMachine'; path='SOFTWARE\\Classes\\V83.InfoBaseList\\shell\\open\\command' }
    $regKeys += @{ leaf='LocalMachine'; path='SOFTWARE\\Classes\\V83.InfoBaseListLink\\shell\\open\\command' }
    $regKeys += @{ leaf='LocalMachine'; path='SOFTWARE\\Classes\\V82.InfoBaseList\\shell\\open\\command' }
    
    foreach( $key in $regKeys ) {
                
         Try {
             $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey( $key.leaf, $env:COMPUTERNAME )
         } Catch {
             Write-Error $_
             Continue
         }
 
         $regkey = $reg.OpenSubKey( $key.path )
         If( -not $regkey ) {
             Write-Warning "Не найдены ключи в: $($string.leaf)\\$($string.path)"
         }
         $defaultValue = $regkey.GetValue("").ToString()
         $index = $defaultValue.IndexOf("1cestart.exe")
         if ( $index -gt 0 ) {
            if ( $defaultValue[0] -eq '"' ) {
                $starterPath = $defaultValue.Substring( 1, $index + 11 )
            } else {
                $starterPath = $defaultValue.Substring( 0, $index + 11 )
            }
            $reg.Close()
            Break
         }
         $reg.Close()
    }

    # попытка поиска через WinRM, если ранее поиск не удался
    if ( -not $starterPath -and $ComputerName -ne $env:COMPUTERNAME ) {
        $starterPath = Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
                            if ( Test-Path "${env:ProgramFiles(x86)}\1cv8\common\1cestart.exe" ) {
                                "${env:ProgramFiles(x86)}\1cv8\common\1cestart.exe" 
                            } elseif ( Test-Path "${env:ProgramFiles(x86)}\1cv82\common\1cestart.exe" ) {
                                "${env:ProgramFiles(x86)}\1cv82\common\1cestart.exe"
                            } else { $null } 
                         } -ErrorAction Continue
    } elseif ( -not $pathToStarter ) {
        $starterPath = if ( Test-Path "${env:ProgramFiles(x86)}\1cv8\common\1cestart.exe" ) {
                                "${env:ProgramFiles(x86)}\1cv8\common\1cestart.exe" 
                            } elseif ( Test-Path "${env:ProgramFiles(x86)}\1cv82\common\1cestart.exe" ) {
                                "${env:ProgramFiles(x86)}\1cv82\common\1cestart.exe"
                            } else { $null }
                              
    }

    $starterPath
}

function Start-1CInstances
<#
.Synopsis
   Запуск указанной версии платформы (если не указана, то запускается последняя)
.DESCRIPTION
   Запуск версии платформы, наиболее подходящей для указанного параметра. Если не указано, то запускается последняя найденная версия.
   Если для заданного параметра поиска платформы найдено несколько экземпляров, то возникает ошибка.
.NOTES  
    Name: oceHelper
    Author: ypermitin@yandex.ru
.LINK  
    https://github.com/YPermitin/PowerShell-For-1C-Developer
.EXAMPLE
   Start-1CInstances "8.3.8.1784"
.OUTPUTS
   null
#>
{
    Param(
        # Версия платформы для поиска
        [string]$PlatformVersion = "*"
    )
    
    $platforms = Get-1CInstances($PlatformVersion) | Sort-Object -property DisplayVersion –Descending

    if ($platforms.length -eq 0)
    {
        Write-Error "Не удалось найти установленную платформу 1С:Предприятие!"
        return
    }

    if($platforms.length -gt 1 -and $PlatformVersion -ne "*")
    {
        Write-Error "Не удалось однозначно определить запускаемую версию платформы!"
        return
    } else
    {
        & ($platforms[0].InstallLocation + "bin\1cv8.exe")
    }
}

function Remove-1CCache
<#
.Synopsis
   Удаляет кэш 1С для всех баз
.DESCRIPTION
   Удаляет кэш 1С на машине для всех баз
.NOTES  
    Name: oceHelper
    Author: ypermitin@yandex.ru
.LINK  
    https://github.com/YPermitin/PowerShell-For-1C-Developer
.EXAMPLE
   Remove-1CCache
.OUTPUTS
    NULL
#>
{
    Param(
    )
    
    (Get-ChildItem "C:\Users\*\AppData\Local\1C\1Cv*\*", "C:\Users\*\AppData\Roaming\1C\1Cv*\*") | Where {$_.Name -as [guid]} |Remove-Item -Force -Recurse
    Write-Host "Кэш успешно очищен!"
}