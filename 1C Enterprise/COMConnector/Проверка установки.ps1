$agentPort = 1540;
$agentAddress = "localhost";
$fullAgentAddress = "tcp://" + $agentAddress + ":" + $agentPort;

try {
    $v83COMConnector = New-Object -COMObject "V83.COMConnector"
    Write-Host "Компонента "V83.COMConnector" зарегистрирована и готова к использованию.";
} 
catch {
    Write-Host "Компонента "V83.COMConnector" не зарегистрирована.";
}