$services1C = Get-WmiObject win32_service | ?{$_.Name -like '*'} |
    Select Name, DisplayName, State, PathName | 
    Where-Object { $_.PathName  -Like "*ragent.exe*" };

$obj = [PSCustomObject] @{
    data = @($services1C | % {
        $serviceInfo = $_
        $serviceExecPath = $serviceInfo.PathName

        $hash = [ordered]@{}
        $serviceExecPath.Split("-").Trim() | Where-Object { $_.Contains(" ") } | ForEach-Object { 
            $name, $value = $_ -split '\s+', 2
            $hash[$name] = $value
        }

        $parsePathAgentExe = $serviceExecPath.Substring(1, $serviceExecPath.Length -1)
        $parsePathAgentExe = $parsePathAgentExe.Substring(0, $parsePathAgentExe.IndexOf('"'))

        if(Test-Path $parsePathAgentExe)
        {
            $platformVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($parsePathAgentExe).FileVersion
        } else
        {
            $platformVersion = ""
        }
        
        $clusterPath = $hash.d -replace '"', ''
        $clusterRegPort = $hash.regport
        $clusterPort = $hash.port
        $clusterPortRange = $hash.range
        $clusterRegPath = "$clusterPath\reg_$clusterRegPort"

        [PSCustomObject] @{
            'Name' = $serviceInfo.Name
            'DisplayName' = $serviceInfo.DisplayName            
            'State' = $serviceInfo.State
            'Version' = $platformVersion
            'ClusterPath' = $clusterPath
            'ClusterRegPort' = $clusterRegPort
            'ClusterPort' = $clusterPort
            'ClusterPortRange' = $clusterPortRange
            'ClusterRegPath' = $clusterRegPath
            'PathName' = $serviceInfo.PathName
        }
    }) 
}

$obj.data | Format-Table