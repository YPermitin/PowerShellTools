<#
Отмена регистрации всех COM-компонентов вне зависиомости от того, как они были зарегистрированы (regsvr32.exe или службы компонентов (comexp.msc))
#>

$allComObjects = [System.Collections.ArrayList]@()

# Поиск COM-компонентов, зарегистрированных с помощью regsvr32.exe
Get-ChildItem HKLM:\Software\Classes -ea 0 | 
    Where-Object { 
        $_.PSChildName -match '^\w+\.\w+$' -and 
        (Get-ItemProperty "$($_.PSPath)\CLSID" -ea 0)
    } | ForEach-Object {
        $COMName = $_.PSChildName    
        $CLSIDProperty = Get-ItemProperty "$($_.PSPath)\CLSID"    
        $CLSID = $CLSIDProperty.'(default)' -replace '{', '' -replace '}', ''
        
        if($CLSID)
        {
            $itemCLSIDKey = "Registry::HKEY_CLASSES_ROOT\CLSID\{$CLSID}"
            if(Test-Path -Path $itemCLSIDKey)
            {
                $ItemCLSID = Get-Item -Path $itemCLSIDKey
                $procInfo = Get-ItemProperty "$($ItemCLSID.PSPath)\InprocServer32" -ErrorAction SilentlyContinue
                if($procInfo)
                {
                    $dllPath = $procInfo.'(default)'

                    if($dllPath -like '*comcntr.dll')
                    {
                        $COMObjectInfo = [PSCustomObject]@{
                            Name = $COMName
                            CLSID = $CLSID
                            DLLPath = $dllPath
                            RegisteredBy = "regsvr32.exe"
                        }

                        $allComObjects.Add($COMObjectInfo) | Out-Null
                    }
                }
            }
        }
    }

# Поиск COM-компонентов, зарегистрированных с помощью службы компонентов
$comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
$applications = $comAdmin.GetCollection("Applications") 
$applications.Populate() 
foreach ($application in $applications)
{

    $components = $applications.GetCollection("Components",$application.key)
    $components.Populate()
    foreach ($component in $components)
    {
        $dllName = $component.Value("DLL")
        if($dllName -like "*comcntr.dll")
        {
            $COMName = $component.Name
            $CLSID = $component.Key -replace "{", "" -replace "}", ""         

            $COMObjectInfo = [PSCustomObject]@{
                Name = $COMName
                CLSID = $CLSID
                DLLPath = $dllName
                RegisteredBy = "comexp.msc"
            }

            $allComObjects.Add($COMObjectInfo) | Out-Null
        }
    }
}

$allComObjects | ForEach-Object {
    if($_.RegisteredBy -eq "regsvr32.exe")    
    {
        $unregCommand = "regsvr32.exe /u ""$($_.DLLPath)""";
        cmd /c "$unregCommand"
        Write-Host "Регистрация компоненты ""$($_.Name)"" успешно отменена!" -ForegroundColor Red
    } elseif($_.RegisteredBy -eq "comexp.msc")  
    {
        $comAdmin = New-Object -comobject COMAdmin.COMAdminCatalog
        $Apps = $comAdmin.GetCollection("Applications")
        $Apps.Populate();
        $AppName = $_.Name -replace "\.", "_";
        $AppFoundedObject = $null
        $AppFoundIndex = -1;
        foreach ($App in $Apps ) {
            $AppFoundIndex = $AppFoundIndex + 1;
            if ($App.Name -eq $AppName ) {
                $AppFoundedObject = $App;     
                break;       
            }
        }
        if($null -ne $AppFoundedObject)
        {
            $Apps.Remove($AppFoundIndex) | Out-Null;
            $Apps.SaveChanges() | Out-Null;
            Write-Host "$AppName removed" -ForegroundColor Red
        }

        Write-Host "Регистрация компоненты ""$($_.Name)"" успешно отменена!" -ForegroundColor Red
    }
}