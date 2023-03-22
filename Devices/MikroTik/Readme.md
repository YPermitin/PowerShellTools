# MikroTik

Управление устройствами компании [MikroTik](https://mikrotik.com/products) на базе [RouterOS](https://mikrotik.com/download).

## Скрипты

Описание скриптов раздела. Все они выполняют команды через SSH, но в версиях RouterOS 7.1+ появится [REST API](https://help.mikrotik.com/docs/display/ROS/REST+API) для выполнения аналогичных действий.

| Имя скрипта | Описание |
| ----------- | -------- |
| [Get-DeviceInfo](Get-DeviceInfo.ps1) | Скрипт получает информацию об использовании ресурсов и статистику маршрутизатора. |
| [Get-DeviceHealth](Get-DeviceHealth.ps1) | Скрипт для получении информации о состоянии оборудования. |
| [Get-DeviceActiveClients](Get-DeviceActiveClients.ps1) | Скрипт получает информацию о текущих подключенных хостах. |
| [Get-DeviceConfiguration](Get-DeviceConfiguration.ps1) | Скрипт для скачивания текущей конфигурации устройства. |

## Полезные ссылки

* [Официальная документация](https://wiki.mikrotik.com/wiki/Main_Page)
* [Официальная документация Router OS](https://help.mikrotik.com/docs/display/ROS/RouterOS)
* [REST API для RouterOS с версии 7.x](https://help.mikrotik.com/docs/display/ROS/REST+API)
