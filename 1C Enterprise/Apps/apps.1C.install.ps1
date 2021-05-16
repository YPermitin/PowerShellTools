$installFilesDirectory = "C:\Soft\1C" # Каталог, где находится установочные файлы
Set-Location $installFilesDirectory;

$msiInstallerPath = "$installFilesDirectory\1CEnterprise 8 (x86-64).msi"
$adminstallrelogonPath = "$installFilesDirectory\adminstallrelogon.mst"
$lang1049Path = "$installFilesDirectory\1049.mst"

$DESIGNERALLCLIENTS = 1
$THICKCLIENT=1
$THINCLIENTFILE=1
$THINCLIENT=1
$WEBSERVEREXT=0
$SERVER=0
$CONFREPOSSERVER=0
$CONVERTER77=0
$SERVERCLIENT=0
$LANGUAGES='RU'
<#
Команда установки 1С с параметрами
#>

$params = '/i', 
          $msiInstallerPath,
          # Сокращенный интерфейс. По сути, при установке пользователь увидит только бегущую полосу прогресса. Можно указать /qn и юзер вообще ничего при установке не увидит.
          '/qr', 
          # Здесь мы подключаем рекомендованную фирмой 1С трансформацию adminstallrelogon.mst и пакет русского языка 1049.mst
          "TRANSFORMS=$adminstallrelogonPath;$lang1049Path", 
          # Это основные компоненты 1С:Предприятия, включая компоненты для администрирования, конфигуратор и толстый клиент. Без этого параметра ставится всегда только тонкий клиент, независимо от следующего параметра
          "DESIGNERALLCLIENTS=$DESIGNERALLCLIENTS",
          "THICKCLIENT=$THICKCLIENT", # Толстый клиент
          "THINCLIENTFILE=$THINCLIENTFILE", # Тонкий клиент, файловый вариант
          "THINCLIENT=$THINCLIENT", # Тонкий клиент
          "WEBSERVEREXT=$WEBSERVEREXT", # Модули расширения WEB-сервера
          "SERVER=$SERVER", # Сервер 1С:Предприятия
          "CONFREPOSSERVER=$CONFREPOSSERVER", # Сервер хранилища конфигураций
          "CONVERTER77=$CONVERTER77", # Конвертер баз 1С:Предприятия 7.7
          "SERVERCLIENT=$SERVERCLIENT", # Администрирование сервера
          "LANGUAGES=$LANGUAGES" # Язык установки – русский.
          $params
& msiexec.exe @params