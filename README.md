# Invoke-OdinApi
Execute Odin "Operations Automation" and "Business Automation" API commands from PowerShell.<br>
Can execute API commands and decode the response or generate a request XML

####Warning!
This module is shipped "as is", I did not fully tested it, Neither I nor anyone else responsible for any loss or damage resulting from using the code in this module.

####BA
* Supports all data types: i4(int),double,"string"
* Decode Base64 fault
* Convert the Result to a Powershell Object from the response XML

####OA
* Supports all data types: int,bigint,string,boolean,base64,struct,array
* Convert the Result to a Powershell Object from the response XML

### How to use
Download https://github.com/ili101/Invoke-OdinApi/archive/master.zip<br>
Extract the zip (with the folder) to: %USERPROFILE%\Documents\WindowsPowerShell\Modules<br>
Then you can start using it, for example:
```powershell
Invoke-OdinApi -OA -Method 'pem.statistics.getStatisticsReport' -Parameters @{reports=@(@{name='poaVersion'; value='0'})} -SendTo '123.123.123.123'
```

### Contributing
Just fork and send pull requests, Thank you!<br>
Format-Xml was written by Jaykul credit goes to him, for the latest version see his repository https://github.com/Jaykul/Xml

### More Examples:
```powershell
[int]$Subscription = 1001880

#region ############ BA Example Calls ############
#<# Example PlaceSubscriptionCancellationOrder_API
$Method = 'PlaceSubscriptionCancellationOrder_API'
$Parameters = [ordered]@{
    'SubscriptionID' = $Subscription
    'CancelType' = [int]30
    'ReasonID' = [int]14
    'Descr' = 'Subscription cancellation'
}
#>

#<# Example SubscriptionDetailsGetEx_API
$Method = 'SubscriptionDetailsGetEx_API'
$Parameters = [ordered]@{
    'SubscriptionID' = $Subscription
}
#>

#<# Example IncrementResourceUsage_API
$Method = 'IncrementResourceUsage_API'
$Parameters = [ordered]@{
    'SubscriptionID' = $Subscription
    'ResourceID' = [int]100003
    'DeltaAmount' = [double]3
}
#>

#<# Example SubscriptionStop_API
$Method = 'SubscriptionStop_API'
$Parameters = [ordered]@{
    'SubscriptionID' = $Subscription
    'Comment' = 'Subscription stopped'
}
#>

#<# Example SubscriptionTakeFromCreditHold_API
$Method = 'SubscriptionTakeFromCreditHold_API'
$Parameters = [ordered]@{
    'SubscriptionID' = $Subscription
    'ReasonID' = [int]1
    'Comment' = 'Released from hold'
}
#>
#endregion ############ BA Example Calls ############


#region ############ OA Example Calls ############
#<# One liner example for pem.statistics.getStatisticsReport
Invoke-OdinApi -OA -Method 'pem.statistics.getStatisticsReport' -Parameters @{reports=@(@{name='poaVersion'; value='0'})} -SendTo '123.123.123.123'
#>

#<# Example pem.getSubscription
$Method = 'pem.getSubscription'
$Parameters = [ordered]@{
    'subscription_id' = $Subscription
    'get_resources' = $true
}
#>

#<# Example pem.batchRequest of pem.statistics.getStatisticsReport and pem.getSubscription
$Method = 'pem.batchRequest'
$getStatisticsReport = @{operation = 'pem.statistics.getStatisticsReport' ; parameters =@(@{reports=@(@{name='poaVersion'; value='0'})}) }
$getSubscription = [ordered]@{
    'operation' = 'pem.getSubscription'
    'parameters' = @([ordered]@{
        'subscription_id' = $Subscription
        'get_resources' = $true
    })
}
$Parameters = @($getStatisticsReport,$getSubscription)
#>

#<# Example pem.setMemberSubscriptionRestrictions
$Method = 'pem.setMemberSubscriptionRestrictions'
$restrictions = [ordered]@{
    'access_all_subscriptions' = $false
    'subscriptions' = @($Subscription,1000753)
}
$Parameters = [ordered]@{
    'member_id' = 1000343
    'restrictions' = $restrictions
}
#>

#<# Fake Example with Base64
# To use the Base64 Class you need to load it the first time from the module with the command "Import-Module Invoke-OdinApi-master"
$Method = 'pem.TestNotReal'
$Parameters = [ordered]@{
    'subscription_id' = $Subscription
    'get_resources' = [Base64]'Base64Text'
}
#>
#endregion ############ OA Example Calls ############

#<# Execute the API call
$Fqdn = '123.123.123.123'
$Out = $null

# For Business Automation
$Out = Invoke-OdinApi -BA -Method $Method -Parameters $Parameters -SendTo $Fqdn #-OutputXml #-Verbose
# For Operations Automation
$Out = Invoke-OdinApi -OA -Method $Method -Parameters $Parameters -SendTo $Fqdn -OutputXml #-Verbose

if ($Out -is [System.Xml.XmlDocument])
{
    Format-Xml -Xml $Out
}
else
{
    $Out
}

# If "-OutputXml" switch was used ypu can then run this
$Out2 = ConvertFrom-OdinApiXml -Xml $Out
$Out2
#>
```
