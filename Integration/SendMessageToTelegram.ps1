<#
Функция для отправки сообщений в Telegram

Автор оригинального скрипта:
https://gist.github.com/techthoughts2

Сам скрипт взят отсюда:
https://gist.github.com/techthoughts2/8b1c20b1bf145103c71bc64704e272bc

Также есть более функциональный модуль для PowerShell:
https://github.com/techthoughts2/PoshGram
#>

<#
.Synopsis
    Sends Telegram text message via Bot API
.DESCRIPTION
    Uses Telegram Bot API to send text message to specified Telegram chat. Several options can be specified to adjust message parameters.
.EXAMPLE
    $bot = "#########:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx"
    $chat = "-#########"
    Send-TelegramTextMessage -BotToken $bot -ChatID $chat -Message "Hello"
.EXAMPLE
    $bot = "#########:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx"
    $chat = "-#########"

    Send-TelegramTextMessage `
        -BotToken $bot `
        -ChatID $chat `
        -Message "Hello *chat* _channel_, check out this link: [TechThoughts](http://techthoughts.info/)" `
        -ParseMode Markdown `
        -Preview $false `
        -Notification $false `
        -Verbose
.PARAMETER BotToken
    Use this token to access the HTTP API
.PARAMETER ChatID
    Unique identifier for the target chat
.PARAMETER Message
    Text of the message to be sent
.PARAMETER ParseMode
    Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message. Default is Markdown.
.PARAMETER Preview
    Disables link previews for links in this message. Default is $false
.PARAMETER Notification
    Sends the message silently. Users will receive a notification with no sound. Default is $false
.OUTPUTS
    System.Boolean
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
    This works with PowerShell Versions 5.1, 6.0, 6.1
    For a description of the Bot API, see this page: https://core.telegram.org/bots/api
    How do I get my channel ID? Use the getidsbot https://telegram.me/getidsbot
    How do I set up a bot and get a token? Use the BotFather https://t.me/BotFather
.COMPONENT
   PoshGram - https://github.com/techthoughts2/PoshGram
.FUNCTIONALITY
    https://core.telegram.org/bots/api#sendmessage
    Parameters 					Type 				Required 	Description
    chat_id 				    Integer or String 	Yes 		Unique identifier for the target chat or username of the target channel (in the format @channelusername)
    text 						String 				Yes 		Text of the message to be sent
    parse_mode 					String 				Optional 	Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.
    disable_web_page_preview 	Boolean 			Optional 	Disables link previews for links in this message
    disable_notification 		Boolean 			Optional 	Sends the message silently. Users will receive a notification with no sound.
    reply_to_message_id 	    Integer 			Optional 	If the message is a reply, ID of the original message
#>
function Send-TelegramTextMessage {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            HelpMessage = '#########:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$BotToken, #you could set a token right here if you wanted
        [Parameter(Mandatory = $true,
            HelpMessage = '-#########')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$ChatID, #you could set a Chat ID right here if you wanted
        [Parameter(Mandatory = $true,
            HelpMessage = 'Text of the message to be sent')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory = $false,
            HelpMessage = 'HTML vs Markdown for message formatting')]
        [ValidateSet("Markdown", "HTML")]
        [string]$ParseMode = "Markdown", #set to Markdown by default
        [Parameter(Mandatory = $false,
            HelpMessage = 'Disables link previews')]
        [bool]$Preview = $false, #set to false by default
        [Parameter(Mandatory = $false,
            HelpMessage = 'Sends the message silently')]
        [bool]$Notification = $false #set to false by default
    )
    #------------------------------------------------------------------------
    $results = $true #assume the best
    #------------------------------------------------------------------------
    $payload = @{
        "chat_id"                   = $ChatID;
        "text"                      = $Message
        "parse_mode"                = $ParseMode;
        "disable_web_page_preview"  = $Preview;
        "disable_notification"      = $Notification
    }#payload
    #------------------------------------------------------------------------
    try {
        Write-Verbose -Message "Sending message..."

        # Раскоментируйте эту строку, если при отправке получаете ошибку вида 
        # "Не удалось создать безопасный канал SSL / TLS"
        #[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12   

        $eval = Invoke-RestMethod `
            -Uri ("https://api.telegram.org/bot{0}/sendMessage" -f $BotToken) `
            -Method Post `
            -ContentType "application/json" `
            -Body (ConvertTo-Json -Compress -InputObject $payload) `
            -ErrorAction Stop
        if (!($eval.ok -eq "True")) {
            Write-Warning -Message "Message did not send successfully"
            $results = $false
        }#if_StatusDescription
    }#try_messageSend
    catch {
        Write-Warning "An error was encountered sending the Telegram message:"
        Write-Error $_
        $results = $false
    }#catch_messageSend
    return $results
    #------------------------------------------------------------------------
}#function_Send-TelegramTextMessage