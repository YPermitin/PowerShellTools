<#
 Функция для проверки блокировки файла другим процессом
#>

function Test-FileLock {
    param (
        [parameter(Mandatory = $true)][string]$Path,
        [parameter(Mandatory = $false)][System.IO.FileAccess]$AccessType = [System.IO.FileAccess]::Read
    )
    $oFile = New-Object System.IO.FileInfo $Path
  
    if ((Test-Path -Path $Path) -eq $false) {
        return $false
    }
  
    try {
        # [System.IO.FileAccess]::Read - проверяется возможность доступа к файлу только на чтение
        # Если нужно проверить доступ на запись, то параметр можно заменить на [System.IO.FileAccess]::ReadWrite
        $oStream = $oFile.Open([System.IO.FileMode]::Open, $AccessType, [System.IO.FileShare]::ReadWrite)
  
        if ($oStream) {
            $oStream.Close()
        }
        return $false
    }
    catch {
        # Файл заблокирован процессом
        return $true
    }
}

$testFile = "C:\swapfile.sys"
$fileLocked = Test-FileLock $testFile ([System.IO.FileAccess]::ReadWrite)
if ($fileLocked -eq $true) {
    Write-Host "Файл бэкапа заблокирован другим приложением."
}