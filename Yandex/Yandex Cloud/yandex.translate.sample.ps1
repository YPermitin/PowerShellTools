<#
Перевод текста с помощью Yandex Translate
Официальная документация: https://cloud.yandex.ru/docs/translate/operations/translate

2. Получаем IAM-токен (https://cloud.yandex.ru/docs/iam/operations/iam-token/create)
#>

# Шаг 1. Убедиться, что платежный аккаунт находится в статусе ACTIVE или TRIAL_ACTIVE (https://console.cloud.yandex.ru/billing?section=accounts)

# Шаг 2. Получите OAuth-токен в сервисе Яндекс.OAuth. Для этого перейдите по ссылке, нажмите Разрешить и скопируйте полученный OAuth-токен.
$yandexPassportOauthToken = "<OAuthТокен>"

# Шаг 3. Получаем IAM-токен (https://cloud.yandex.ru/docs/iam/operations/iam-token/create). 
# В примере ниже это будет выполняться через API, а не CLI.
# Время жизни IAM-токена — не больше 12 часов, но рекомендуется запрашивать его чаще, например каждый час.
$Body = @{ yandexPassportOauthToken = "$yandexPassportOauthToken" } | ConvertTo-Json -Compress
$iamToken = Invoke-RestMethod -Method 'POST' -Uri 'https://iam.api.cloud.yandex.net/iam/v1/tokens' -Body $Body -ContentType 'Application/json' | Select-Object -ExpandProperty iamToken

# Шаг 4. Получаем идентификатор облака. В примере берем только первый элемент.
$cloudInfo = Invoke-RestMethod -Method 'GET' -Uri 'https://resource-manager.api.cloud.yandex.net/resource-manager/v1/clouds' -Headers @{Authorization = "Bearer $iamToken"} -Body $Body -ContentType 'Application/json'
$cloudId = $cloudInfo.clouds[0].id

# Шаг 5. Получаем идентификатор любого каталога, на который у аккаунта есть роль editor или выше.
# Чтобы получить список каталогов с идентификаторами, воспользуйтесь методом list для ресурса Folder.
$folderInfo = Invoke-RestMethod -Method 'GET' -Uri "https://resource-manager.api.cloud.yandex.net/resource-manager/v1/folders?cloud_id=$cloudId" -Headers @{Authorization = "Bearer $iamToken"} -Body $Body -ContentType 'Application/json'
$folderId = $folderInfo.folders[0].id

# Шаг 6. Переводим текст
# Пошаговая инструкция https://cloud.yandex.ru/docs/translate/operations/translate
# Официальная документация https://cloud.yandex.ru/docs/translate/?utm_source=console&utm_medium=empty-page&utm_campaign=translate
$sourceLanguage = 'ru'; # Язык назначения
$targetLanguage = 'en'; # Язык назначения
$text = "Привет из космоса!", "Все будет хорошо!", "1С великолепна!!!"
$postData = @{
    sourceLanguageCode = $sourceLanguage
    targetLanguageCode = $targetLanguage    
    texts = $text
    folderId = $folderId
    glossaryConfig = @{
        glossaryData = @{
            glossaryPairs = @(
                @{
                    sourceText = "1С великолепна"
                    translatedText = ".NET is awesome"
                }
            )
        }
    }
}
$postDataAsJson = $postData | ConvertTo-Json -Depth 5
$operationResult = Invoke-RestMethod -Method 'POST' -ContentType 'application/json; charset=UTF-8' -Uri 'https://translate.api.cloud.yandex.net/translate/v2/translate' -Headers @{Authorization = "Bearer $iamToken"} -Body $postDataAsJson # -OutFile "D:\Trash\result.log"
$operationResult

Write-Host "Результаты перевода текста."
$operationResult.translations
$operationResult.translations | ForEach-Object {
    $_.text
}

<#
Результат перевода:
Greetings From Outer Space!
Everything will be fine!
.NET is awesome!!!
#>
