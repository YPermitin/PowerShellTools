<#
Пример скрипта отправки почтовых сообщений сервисом Yandex Mail.
Для других сервисов скрипт будет примерно таким же, но могут отличатсья параметры. См. инструкции сервиса.
#>

# Параметры почтового сервера
$serverSmtp = "smtp.yandex.ru" # Адрес сервера
$port = 587 # Порт
$From = "login@yandex.ru" # Отправитель
$To = "login@mail.ru" # Получатель
$subject = "Всем привет!" # Тема

$user = "login@yandex.ru" # Пользователь
$pass = '<Pas$w0rd>' # Пароль

# Формируем письмо
$mes = New-Object System.Net.Mail.MailMessage
$mes.From = $from # Отправитель
$mes.To.Add($to) # Добавляем получателя
$mes.Subject = $subject # Указываем тему
$mes.IsBodyHTML = $true # Устанавливаем флаг, что письмо в формате HTML
$mes.Body = "<h1>Доброго дня!</h1>" # Задаем тело письма

#Добавляем файл по указанному пути в качестве вложения
# $file = "C:\Docs\SomeDoc.xlsx"
# $att = New-object Net.Mail.Attachment($file)
# $mes.Attachments.Add($att) 

# Настраиваем подключение к почтовому серверу
$smtp = New-Object Net.Mail.SmtpClient($serverSmtp, $port)
$smtp.EnableSSL = $true # Включаем использование SSL
# Настраиваем данные аутентификации
$smtp.Credentials = New-Object System.Net.NetworkCredential($user, $pass); 

# Отправляем письмо
$smtp.Send($mes) 
# Очищаем данные присоединенных файлов
# $att.Dispose()