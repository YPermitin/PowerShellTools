function Delete-SqlDatabase($serverName, $databaseName) {    
    
    Import-Module SQLPS -WarningAction SilentlyContinue 3>$null
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverName)

    $db = $server.databases[$databaseName]
    if ($db) {
     
        Write-Host "Start killing sessions..." -BackgroundColor Blue
      $server.KillAllprocesses($databaseName)
      Write-Host "OK!" -BackgroundColor Green
      
      Write-Host "Start droping database..." -BackgroundColor Blue
      $db.Drop()
      Write-Host "OK!" -BackgroundColor Green

    } else {
      Write-Host "Database is not exists!"
    }
  }

  Delete-SqlDatabase "localhost" "DatabaseNameForDropping"