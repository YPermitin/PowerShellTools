try {
    $v83COMConnector = New-Object -COMObject "V83.COMConnector"
    Write-Host "Компонента "V83.COMConnector" зарегистрирована и готова к использованию." -ForegroundColor Green;
} 
catch {
    Write-Host "Компонента "V83.COMConnector" не зарегистрирована." -ForegroundColor Red;
}

try {
    $v82COMConnector = New-Object -COMObject "V82.COMConnector"
    Write-Host "Компонента "V82.COMConnector" зарегистрирована и готова к использованию." -ForegroundColor Green;
} 
catch {
    Write-Host "Компонента "V82.COMConnector" не зарегистрирована." -ForegroundColor Red;
}