<#
Пример работы с COM+ приложениями (https://serverfault.com/questions/256403/how-do-you-administer-com-from-powershell)
#>

$AppID = "{123456789}"
$CLSID = "{123456789}"
$comAdmin = New-Object -comobject COMAdmin.COMAdminCatalog

function InstallApplication ( $comAdmin ) {
    $AppName = "foobar"
    $AppDesc = "foobar com plus object does stuff"

    $apps = $comAdmin.GetCollection("Applications")
    $apps.Populate();

    $appFound = $false
    foreach ($app in $apps ) {
        if ($app.Name -eq $AppName ) {
            $appFound = $true
            #break
        }
    }
    if (!($appFound )) {
        $app = $apps.Add()
        $app.Value("ID") = $AppID
        $app.Value("Name") = $AppName
        $app.Value("Description") = $AppDesc
        $app.Value("ApplicationAccessChecksEnabled") = $True
        $app.Value("AccessChecksLevel") = 1 #Component level
        $app.Value("Activation") = "Local"
        $apps.SaveChanges();
    }
    Else {
        Write-Host "$AppName already exists, skipping" -ForegroundColor green
    }

}
function InstallComponents( $comAdmin ) {

    $comAdmin.ImportComponent( $AppID, $CLSID )

    # Configure the directory service component
    $apps = $comAdmin.GetCollection("Applications")
    $apps.Populate();

    $comps = $apps.GetCollection("Components", $AppID)
    $comps.Populate();
    ForEach ($comp in $comps) {
        If ($comp.Key -eq $CLSID) {
            $ComponentFound = $True
            #break
        }
    }

    If ($ComponentFound) {
        $comp.Value("Description") = "foobar "
        $comp.Value("ComponentAccessChecksEnabled") = $true
        $comp.Value("ObjectPoolingEnabled") = $true
        $comp.Value("JustInTimeActivation") = $false
        $comp.Value("Synchronization") = 2  #Supported
        $comp.Value("Transaction") = 1      #Not supported
        $comps.SaveChanges();
    }
    Else {
        Write-Warning "CLSID $CLSID not found"
    }
}
function ConfigureSecurity( $comAdmin ) {

    $apps = $comAdmin.GetCollection("Applications")
    $apps.Populate();

    # Add Administrator, and User roles to the application.
    #https://msdn.microsoft.com/en-us/library/windows/desktop/ms678849%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396
    $roles = $apps.GetCollection("Roles", $AppID)
    $roles.Populate();

    $found = $false
    foreach ( $role in $roles ) {
        if ($role.Key -eq "Administrators") {
            $found = $true
            #break
        }
    }
    if (!($found)) {
        $role = $roles.Add()
        $role.Value("Name") = "Administrators"
    }

    $found = $false
    foreach ($role in $roles ) {
        if ($role.Key -eq "Users") {
            $found = $true
            #break
        }
    }

    if (!($found)) {
        $role = $roles.Add()
        $role.Value("Name") = "Users"
    }

    $roles.SaveChanges();

  # Assign accounts to the roles

    $domain = (Get-WmiObject Win32_ComputerSystem).Domain
    if ($domain -like 'WORKGROUP') {
        Write-Warning "Not joined to domain, skipping com+ roles"
    }
    else {
        $users = $roles.GetCollection("UsersInRole", "Users")
        $user = $users.Add()
        $roleDescription = "$domain" + "\" + "Users"
        Write-Host "Adding com+ role $roleDescription" -ForegroundColor green
        $user.Value("User") = $roleDescription
        $users.SaveChanges();


        $users = $roles.GetCollection("UsersInRole", "Administrators")
        $user = $users.Add()
        $roleDescription = "$domain" + "\" + "fooAdmin"
        Write-Host "Adding com+ role $roleDescription" -ForegroundColor green
        $user.Value("User") = $roleDescription
        $user = $users.Add()
        $roleDescription = "$domain" + "\" + "barAdmin"
        Write-Host "Adding com+ role $roleDescription" -ForegroundColor green
        $user.Value("User") = $roleDescription
        $users.SaveChanges();

        # Configure component to allow access to role.
        $comps = $apps.GetCollection("Components", $AppID)
        $comps.Populate();

        ForEach ($comp In $comps ) {
          If ($comp.Key -eq $CLSID) {
              $ComponentFound = $True
              #  break
          }
        }
        If ($ComponentFound ) {
            $RolesForComponent = $comps.GetCollection("RolesForComponent", $CLSID)
            $RoleForComponent = $RolesForComponent.Add()
            $RoleForComponent.Value("Name") = "Administrators"
            $RoleForComponent = $RolesForComponent.Add()
            $RoleForComponent.Value("Name") = "Users"
            $RolesForComponent.SaveChanges();
        }
        Else {
            Write-Warning "CLSID $CLSID not found"
        }
    }


}

InstallApplication $comAdmin
InstallComponents $comAdmin
ConfigureSecurity $comAdmin