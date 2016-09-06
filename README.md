# Invoke-OdinApi
### How to use
Download https://github.com/ili101/Invoke-OdinApi/archive/master.zip
Extract the zip (with the folder) to: %USERPROFILE%\Documents\WindowsPowerShell\Modules

### Examples:
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
    'Comment' = 'Subscription stopped due to hold'
}
#>

#<# Example SubscriptionTakeFromCreditHold_API
$Method = 'SubscriptionTakeFromCreditHold_API'
$Parameters = [ordered]@{
    'SubscriptionID' = $Subscription
    'ReasonID' = [int]1
    'Comment' = 'Subscription cancellation due to hold'
}
#>

#<# Execute BA
$Fqdn = '123.123.123.123:5224'

$Xml = Invoke-OdinApi -BA -Method $Method -Parameters $Parameters -SendTo $Fqdn 
if ($Xml -is [System.Xml.XmlDocument])
{
    Format-Xml -Xml $Xml
}
else
{
    $Xml
}
#>
#endregion ############ BA Example Calls ############

#region ############ OA Example Calls ############
#<# One liner example for pem.statistics.getStatisticsReport
$Xml = Invoke-OdinApi -OA -Method 'pem.statistics.getStatisticsReport' -Parameters @{reports=@(@{name='poaVersion'; value='0'})} -SendTo '123.123.123.123:8440'
Format-Xml -Xml $Xml
#>

#<# Example pem.getSubscription
$Method = 'pem.getSubscription'
$Parameters = [ordered]@{
    'subscription_id' = $Subscription
    'get_resources' = $true
}
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
$Method = 'pem.TestNotReal'
$Parameters = [ordered]@{
    'subscription_id' = $Subscription
    'get_resources' = [Base64]'Base64Text'
}
#>

#<# Execute OA
$Fqdn = '123.123.123.123:8440'

$Xml = $null
$Xml = Invoke-OdinApi -OA -Method $Method -Parameters $Parameters #-SendTo $Fqdn #-Verbose
if ($Xml -is [System.Xml.XmlDocument])
{
    Format-Xml -Xml $Xml
}
else
{
    $Xml
}
#>
#endregion ############ OA Example Calls ############
```