function Get-ActualReleasesInfo
<#
.Synopsis
   Получение списка актуальных релизов с сайта users.v8.1c.ru
.DESCRIPTION
   Получение списка актуальных релизов с сайта users.v8.1c.ru
.NOTES  
    Name: oceHelper
    Author: ypermitin@yandex.ru
.LINK  
    https://github.com/YPermitin/PowerShell-For-1C-Developer
.EXAMPLE
   Get-ActualReleases
.OUTPUTS
   Объект класса 'ReleasesGetter' для работы с данными сайта 'users.v8.1c.ru/actual.jsp'
#>
{
    Param(    )
    
    $oceReleasesLib = (Get-Module oce-releases).Path.TrimEnd('oce-releases.psm1') + "libs\DevelPlatform.OCE.GetterPlatformInfo.dll"
    Add-Type -Path $oceReleasesLib

    $releasesGetter = new-object DevelPlatform.OCE.GetterReleasesInfo.ReleasesGetter

    $releasesGetter
}