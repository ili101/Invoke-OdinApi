Pause
[int]$Subscription = 1001880

#region ############ BA Example Methods ############
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

#<# Example SubscriptionStatusUpdate_API
$Method = 'SubscriptionStatusUpdate_API'
$Parameters = [ordered]@{
    'SubscriptionID' = $Subscription
    'Status' = 60
    'ServStatus' = 10
}
#>

#<# Example OrderStatusChange_API (Use -AddSignature)
$Method = 'OrderStatusChange_API'
$Parameters = [ordered]@{
    'OrderID' = 3606153
    'NewOrderStatus ' = 'CP'
}
#>
#endregion ############ End BA Example Methods ############


#region ############ OA Example Methods ############
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
#endregion ############ End OA Example Methods ############


#region ############ Execute the API call ############
#<# Execute the API call
$Fqdn = '123.123.123.123'

$Out = $null
# For Business Automation
$Out = Invoke-OdinApi -BA -Method $Method -Parameters $Parameters -SendTo $Fqdn #-Verbose #-Execute:$false #-OutputXml
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

# If "-OutputXml" switch was used you can then run this to convert the XML
$Out2 = ConvertFrom-OdinApiXml -Xml $Out
$Out2
#>
#endregion ############ End Execute the API call ############