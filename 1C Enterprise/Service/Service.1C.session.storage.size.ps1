<#
Получение информации о размере каталога кластера 1С и каталога сеансовых данных
#>

function Get-Size {
    param([string]$pth)
    ((gci -path $pth -recurse | measure-object -property length -sum).sum / 1mb)
}

$services1C = Get-WmiObject win32_service | ? { $_.Name -like '*' } |
Select Name, DisplayName, State, PathName | 
Where-Object { $_.PathName -Like "*ragent.exe*" };

$obj = [PSCustomObject] @{
    data = @($services1C | % {
            $serviceInfo = $_
            $serviceExecPath = $serviceInfo.PathName

            $hash = [ordered]@{}
            $serviceExecPath.Split("-").Trim() | Where-Object { $_.Contains(" ") } | ForEach-Object { 
                $name, $value = $_ -split '\s+', 2
                $hash[$name] = $value
            }

            $clusterPath = $hash.d -replace '"', ''

            $clusterDataSize = 0
            if (Test-Path $clusterPath) {
                $clusterDataSize = Get-Size $clusterPath
            }

            $clusterRegPort = $hash.regport
            $clusterRegDirectory = Join-Path -Path $clusterPath -ChildPath "reg_$clusterRegPort"
            
            $storageSessionDataSizeMb = 0
            Get-ChildItem $clusterRegDirectory | 
            Where-Object { $_.Name -like "snccntx*" } |
            ForEach-Object {
                $storageSessionDataPath = Join-Path -Path $clusterRegDirectory -ChildPath $_
                $folderSize = Get-Size $storageSessionDataPath
                $storageSessionDataSizeMb = $storageSessionDataSizeMb + $folderSize
            }

            [PSCustomObject] @{
                'Name'              = $serviceInfo.Name
                'DisplayName'       = $serviceInfo.DisplayName        
                'ClusterPath'       = $clusterPath
                'ClusterFolderSizeMb' = $clusterDataSize
                'SessionStorageSizeMb' = $storageSessionDataSizeMb
            }
        }) 
}

$obj.data | Format-Table