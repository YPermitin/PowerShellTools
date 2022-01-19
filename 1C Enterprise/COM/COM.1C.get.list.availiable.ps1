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
            #$component            

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

$allComObjects | Format-Table