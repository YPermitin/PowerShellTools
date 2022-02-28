<#
Скрипт для регистрации множества COM-компонентов платформы 1С на одной машине.

Может быть использовано для регистрации одной компоненты через службы компонентов (comexp.msc) под стандартным именем.
Для этого в списке компонентов для регистрации достаточно указать, например:
[pscustomobject]@{Name="V82.COMConnector";DLLPath="C:\Program Files\1cv82\8.2.19.130\bin\comcntr.dll";UserName="yy\ypermitin";UserPassword="";CLSID=""},

Полезные ссылки:
https://docs.microsoft.com/ru-ru/windows/win32/api/_cos/
https://serverfault.com/questions/256403/how-do-you-administer-com-from-powershell
https://stackoverflow.com/questions/28729018/how-to-modify-com-applications-from-powershell
https://infostart.ru/public/610960/
https://infostart.ru/1c/articles/685924/
#>

# Предварительно перечислеяем COM-компоненты для регистрации с их путями до DLL, а также параметры авторизации для каждого приложения (пользователя и пароль)
# По указанному имени после регистрации можно будет обращаться к этому COM-компоненту из скриптов или самой платформы 1С.
# Поле CLSID не нужно заполнять (!!!). Оно будет заполнено автоматически присвоенным ID при регистрации компоненты.
$dllForRegistration =
@(
    [pscustomobject]@{Name="V8.2.19.130.COMConnector";DLLPath="C:\Program Files\1cv82\8.2.19.130\bin\comcntr.dll";UserName="yy\ypermitin";UserPassword="";CLSID=""},
    [pscustomobject]@{Name="V8.3.6.2530.COMConnector";DLLPath="C:\Program Files\1cv8\8.3.6.2530\bin\comcntr.dll";UserName="yy\ypermitin";UserPassword="";CLSID=""},
    [pscustomobject]@{Name="V8.3.8.2442.COMConnector";DLLPath="C:\Program Files\1cv8\8.3.8.2442\bin\comcntr.dll";UserName="yy\ypermitin";UserPassword="";CLSID=""}
);

function InstallApplication($comAdmin, $comObjectName, $DLLPath, $username = "", $userpassword = "") {

    $AppID = "{$(New-Guid)}".ToUpper();
    $AppName = $comObjectName -replace "\.", "_";
    $AppDesc = "Application for COM-component ""$AppName""";

    $Apps = $comAdmin.GetCollection("Applications")
    $Apps.Populate();

    $AppFound = $false
    $AppFoundedObject = $null
    $AppFoundIndex = -1;
    foreach ($App in $Apps ) {
        $AppFoundIndex = $AppFoundIndex + 1;
        if ($App.Name -eq $AppName ) {
            $AppFound = $true;
            $AppFoundedObject = $App;     
            break;       
        }
    }

    if($null -ne $AppFoundedObject)
    {
        $Apps.Remove($AppFoundIndex);
        $Apps.SaveChanges();
        Write-Host "$AppName removed" -ForegroundColor Red
        $AppFound = $false;
    }

    $NewApp = $null
    if (!($AppFound)) {
        $NewApp = $Apps.Add()
        $NewApp.Value("ID") = $AppID
        $NewApp.Value("Name") = $AppName
        $NewApp.Value("Description") = $AppDesc
        $NewApp.Value("ApplicationAccessChecksEnabled") = $True
        $NewApp.Value("AccessChecksLevel") = 1 #Component level
        $NewApp.Value("Activation") = "Local"

        if(![string]::IsNullOrEmpty($username) -and ![string]::IsNullOrEmpty($userpassword))
        {
            $NewApp.Value("Identity") = $username;
            $NewApp.Value("Password") = $userpassword;
        }

        $Apps.SaveChanges() # | Out-Null
        Write-Host "$AppName successfully registered" -ForegroundColor Green
    }
    Else {
        Write-Host "$AppName already exists, skipping" -ForegroundColor Green
    }

    $registeredApplication = [pscustomobject]@{
        AppId=$AppID;
        AppName=$AppName;
        AppDesc=$AppDesc;
        NewApp=$NewApp;
        DLLPath = $DLLPath;
        COMObjectName = $comObjectName;
    }
    $registeredApplication
}

function InstallComponent($comAdmin, $registeredApplication) {
    $AppDLL = $registeredApplication.DLLPath;
    $AppID = $registeredApplication.AppId;   
    $comAdmin.InstallComponent($AppID, $AppDLL, "", "");
    
    $Apps = $comAdmin.GetCollection("Applications")
    $Apps.Populate();
        
    $Comps = $Apps.GetCollection("Components", $AppID)
    $Comps.Populate();
    ForEach ($Comp in $Comps) {
        $comAdmin.AliasComponent($AppID, $($Comp.Key), $AppID, $($registeredApplication.COMObjectName), "") | Out-Null;
        break;
    }

    $Comps = $Apps.GetCollection("Components", $AppID)
    $Comps.Populate();
    $CompIndex = -1;
    $newCreatedComponent = $null;
    ForEach ($Comp in $Comps) {
        $CompIndex = $CompIndex + 1;
        if($Comp.Name -ne $registeredApplication.COMObjectName)
        {
            $Comps.Remove($CompIndex);
            $Comps.SaveChanges() | Out-Null;
        } else
        {
            $newCreatedComponent = $Comp;
        }
    }

    $registeredComponent = [pscustomobject]@{
        CLSID = $newCreatedComponent.Key
        Name = $newCreatedComponent.Name
    }
    $registeredComponent
}

function ConfigureSecurity($comAdmin, $registeredApplication, $registeredComponent, $username = "") {

    $AppID = $registeredApplication.AppId;   
    $CLSID = $registeredComponent.CLSID

    $Apps = $comAdmin.GetCollection("Applications")
    $Apps.Populate();

    # Добавляем права доступа на приложение и компоненты.
    #https://msdn.microsoft.com/en-us/library/windows/desktop/ms678849%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396
    $Roles = $Apps.GetCollection("Roles", $AppID)
    $Roles.Populate();

    $found = $false
    foreach ( $Role in $Roles ) {
        if ($Role.Key -eq "CreatorOwner") {
            $found = $true
        }
    }
    if (!($found)) {
        $Role = $Roles.Add()
        $Role.Value("Name") = "CreatorOwner"
    }
    $Roles.SaveChanges();

    if(![string]::IsNullOrEmpty($username))
    {
        $Users = $Roles.GetCollection("UsersInRole", "CreatorOwner")
        $User = $Users.Add()
        $User.Value("User") = $username
        $Users.SaveChanges();

        $Comps = $apps.GetCollection("Components", $AppID)
        $Comps.Populate();

        ForEach ($Comp In $Comps ) {
          If ($Comp.Key -eq $CLSID) {
              $ComponentFound = $True
          }
        }
        If ($ComponentFound ) {
            $RolesForComponent = $Comps.GetCollection("RolesForComponent", $CLSID)
            $RoleForComponent = $RolesForComponent.Add()
            $RoleForComponent.Value("Name") = "CreatorOwner"
            $RolesForComponent.SaveChanges();
        }
        Else {
            Write-Warning "CLSID $CLSID not found"
        }
    }
}

$comAdmin = New-Object -comobject COMAdmin.COMAdminCatalog

# Выполнение регистрации всех компонентов
$dllForRegistration | ForEach-Object {   
    # Создаем приложение COM+ для каждой версии COM-компоненты
    $registeredApplication = InstallApplication $comAdmin $($_.Name) $($_.DLLPath) $($_.UserName) $($_.UserPassword)

    # Регистрируем COM-компонету в приложении и корректируем ее псевдоним
    $registeredComponent = InstallComponent $comAdmin $registeredApplication
    $_.CLSID = $registeredComponent.CLSID;

    # Обновить настройки доступа
    ConfigureSecurity $comAdmin $registeredApplication $registeredComponent $($_.UserName)
}

# Корректруем настройки реестра, "сломанные" после регистрации нескольких COM-компонентов 1C
$dllForRegistration | ForEach-Object {
    $destDLLPath = $($_.DLLPath);
    $itemCLSIDKey = "Registry::HKEY_CLASSES_ROOT\CLSID\$($_.CLSID)"
    if(Test-Path -Path $itemCLSIDKey)
    {
        $ItemCLSID = Get-Item -Path $itemCLSIDKey
        $procInfo = Get-ItemProperty "$($ItemCLSID.PSPath)\InprocServer32" -ErrorAction SilentlyContinue
        if($procInfo)
        {
            $dllPath = $procInfo.'(default)'
            if($destDLLPath -ne $dllPath)
            {
                Set-ItemProperty "$($ItemCLSID.PSPath)\InprocServer32" -Name '(default)' -Value $destDLLPath
                Write-Host "Fixed DLL path for ""$($_.Name)"" to ""$($destDLLPath)"" from ""$dllPath""" -ForegroundColor Green
            }
        }
    }
}