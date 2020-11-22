$services1C = Get-WmiObject win32_service | ?{$_.Name -like '*'} |
    Select Name, DisplayName, State, PathName | 
    Where-Object { $_.PathName  -Like "*ragent.exe*" };

$obj = [PSCustomObject] @{
    data = @($services1C | % {
        $serviceInfo = $_;

        $hash = [ordered]@{}
        $serviceExecPath.Split("-").Trim() | Where-Object { $_.Contains(" ") } | ForEach-Object { 
            $name, $value = $_ -split '\s+', 2
            $hash[$name] = $value
        }

        $platformVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($serviceExecPathRagent).FileVersion        
        $clusterPath = $hash.d -replace '"', ''
        $clusterRegPort = $hash.regport
        $clusterPort = $hash.port
        $clusterPortRange = $hash.range
        $clusterRegPath = "$clusterPath\reg_$clusterRegPort"

        [PSCustomObject] @{
            'Name' = $serviceInfo.Name
            'DisplayName' = $serviceInfo.DisplayName
            'PathName' = $serviceInfo.PathName
            'State' = $serviceInfo.State
            'Version' = $platformVersion
            'ClusterPath' = $clusterPath
            'ClusterRegPort' = $clusterRegPort
            'ClusterPort' = $clusterPort
            'ClusterPortRange' = $clusterPortRange
            'ClusterRegPath' = $clusterRegPath
        }
    }) 
}

$obj.data | Format-Table