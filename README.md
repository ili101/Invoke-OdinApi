# Invoke-OdinApi
Execute Odin "Operations Automation" and "Business Automation" API commands from PowerShell.<br>
Can execute API commands and decode the response or generate a request XML.

#### Warning
This is not an official module.

#### BA
* Build the XML structure.
* Optional parameters `-AddSignature` , `-language`, `-ServerString`, `-Credential`.
* Decodes Base64 fault.

#### OA
* Support the BigInt custom type.
* Catch status <> 0 fault.

#### XML-RPC helper functions.
This functions are not exposed in the module but if you will like to use them for something else that uses XML-RPC you can use `ConvertTo-XmlRpcMethodCall` and `ConvertFrom-XmlRpc` from the `XmlRpc.ps1` file.
* Converts to and from XML-RPC Request/Response.
* Supports all data types: Int(i4) ,Double , String, Boolean, Struct, Array.
* Supported Int64 modes "Error", "Int", "Double", "BigInt".
* Include Base64 custom type.
* Handle faults.

### How to use
Download and install by opening PowerShell and running:
```powershell
# Install for all users (Require running PowerShell as Admin to install)
Install-Module -Name Invoke-OdinApi

# Install for Current User only
Install-Module -Name Invoke-OdinApi -Scope CurrentUser
```
Then you can start using it, for example:
```powershell
Invoke-OdinApi -OA -Method 'pem.statistics.getStatisticsReport' -Parameters @{reports=@(@{name='poaVersion'; value='0'})} -Server '123.123.123.123'
```

### Contributing
Just fork and send pull requests, Thank you!<br>
Format-Xml was written by Jaykul credit goes to him, for the latest version see his repository https://github.com/Jaykul/Xml

### More Examples:
[Invoke-OdinApi Example.ps1](https://github.com/ili101/Invoke-OdinApi/blob/master/Examples/Invoke-OdinApi%20Example.ps1)

### ChangeLog:
[ChangeLog.md](https://github.com/ili101/Invoke-OdinApi/blob/master/ChangeLog.md)
