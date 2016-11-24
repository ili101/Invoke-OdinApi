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
Download and install by opening PowerShell and running:
```powershell
# Install for all users (Require running PowerShell as Admin to install)
Install-Module -Name Invoke-OdinApi

# Install for Current User only
Install-Module -Name Invoke-OdinApi -Scope CurrentUser
```
Then you can start using it, for example:
```powershell
Invoke-OdinApi -OA -Method 'pem.statistics.getStatisticsReport' -Parameters @{reports=@(@{name='poaVersion'; value='0'})} -SendTo '123.123.123.123'
```

### Contributing
Just fork and send pull requests, Thank you!<br>
Format-Xml was written by Jaykul credit goes to him, for the latest version see his repository https://github.com/Jaykul/Xml

### More Examples:
(https://github.com/ili101/Invoke-OdinApi/blob/master/Examples/Invoke-OdinApi Example.ps1)

### ChangeLog:
(https://github.com/ili101/Invoke-OdinApi/blob/master/ChangeLog.md)