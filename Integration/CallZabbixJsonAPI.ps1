<#
Пример вызова JSON-API Zabbix
#>
function CheckZabbixApi($zbxUserName, $zbxUserPassword, $zbxBaseUrl)
{
    $params = @{
        body =  @{
            "jsonrpc"= "2.0"
            "method"= "user.login"
            "params"= @{
                "user"= $zbxUserName
                "password"= $zbxUserPassword
            }
            "id"= 1
            "auth"= $null
        } | ConvertTo-Json
        uri = "$zbxBaseUrl/api_jsonrpc.php"
        headers = @{"Content-Type" = "application/json"}
        method = "Post"
    }

    $result = Invoke-WebRequest @params
    $statusCode = $result.StatusCode
    if($statusCode -ne 200)
    {
        throw "Wrong answer from API: $statusCode"
    }
}