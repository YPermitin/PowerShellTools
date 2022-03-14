<#
Загрузка контактов и создание групп контактов в клиентском приложении MS Outlook
#>

# Исходные данные контактов, которые могут быть получены любым доступным способом (API, загрузка из файла и т.д.)
$contactsByGroup = @{}
$department = "Тюмень"
$contactListForGroup = New-Object System.Collections.Generic.List[System.Object];
$contactsByGroup.Add($department, $contactListForGroup);
$contactsByGroup[$department].Add(@{
    innerPhone = "+79220000000"
    fullName   = "Джон Генри"
    email      = "john123@corp.ru"
}); 

# Инициализация объекта приложения
$outlook = new-object -com Outlook.Application -ea 1;
# Текущая сессия рабоыт с приложением
$outlookSession = $outlook.session;
# Каталог контактов по умолчанию
$contactsFolder = $outlookSession.GetDefaultFolder(10);

$contactsByGroup.Keys | ForEach-Object {
    $contactGroupName = $_;

    # Выполняем поиск группы контактов. Если не смогли найти, то создаем.
    # В этом случае группа контактов - это список рассылки. Также можно создавать группу контактов,
    # вложенную непосредственно в группу. Тут кому как удобно.
    $subfolerItem = $null
    try
    {
        $subfolerItem = $contactsFolder.Items.Item($contactGroupName);
        $subfolerItem.Delete();
    } catch
    {
        # Действий не требуется
    }

    $dl = $contactsFolder.Items.Add("IPM.DistLIst");
    $dl.DLName = $contactGroupName;
    $dl.Save()  | Out-Null;
    $subfolerItem = $contactsFolder.Items.Item($contactGroupName);

    <#
    # Это пример создания вложенной группы.
    $subfolerItem = $null
    try
    {
        $subfolerItem = $contactsFolder.Folders.Item($contactGroupName);
        $subfolerItem.Delete();
    } catch
    {
        # Действий не требуется
    }
    $dl = $contactsFolder.Folders.Add("IPM.DistLIst");
    $dl.DLName = $contactGroupName;
    $dl.Save() | Out-Null;
    $subfolerItem = $contactsFolder.Folders.Item($contactGroupName);
    #>

    # Обходим контакты в кажой группе и создаем их. При этом в группу контактов (группу рассылки)
    #  добавляем нужные данные контактов.
    $contactsByGroup[$contactGroupName] | ForEach-Object {
        Write-Host "Контакт $($_.email) ($contactGroupName)..."

        $fullName = $_.fullName.Trim();  
        $email = $_.email.Trim();     

        # Если контакт уже существует, то удаляем его, чтобы создать заново.
        @($contactsFolder.Items).
            Where{ $_.MessageClass -eq "IPM.Contact" }.            
            Where{ $_.Email1Address -eq $email } | 
            ForEach-Object {
                $_.Delete();
                Write-Host " УДАЛЕН!"
            }      

        Write-Host " Начало создания контакта..."
        $newcontact = $contactsFolder.Items.Add()
        $newcontact.Title = $fullName;
        $newcontact.Email1Address = $_.email;
        $newcontact.Email1DisplayName = "$fullName ($email)"
        $newcontact.BusinessTelephoneNumber = $_.innerPhone;
        $newcontact.Department = $contactGroupName;
        $newcontact.Companies = "Моя компания"
        $newcontact.FullName = $fullName;
        # Заполняем другие свойства контакта в зависимости от задачи.
        $newcontact.Save();
        Write-Host " Контакт СОЗДАН!"
        
        # Создаем объект получаетеля для группы рассылки.
        # Если создается группа контактов, то это действие не требуется.
        # Получатель определяется по EMAIL, который передается в конструктор.
        $recipientByContact = $outlookSession.CreateRecipient($email);
        $recipientByContact.Resolve(); # Сопоставляем адрес с уже сущестующим контактом
        # $recipientByContact.Resolved # Тут должно быть TRUE, чтобы контакт был добавлен в список рассылки
        if($recipientByContact)
        {
            $subfolerItem.AddMember($recipientByContact);
            $subfolerItem.Save() | Out-Null;
        }
    }    
}
