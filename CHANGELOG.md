## 2.0.1 - 2019-11-19
* Remove UTF-8 BOM.
* Change log fix.

## 2.0.0 - 2019-09-23
* Separated the module to `XmlRpc.ps1` (XML-RPC standard) and `Invoke-OdinApi.ps1` (Specific Odin implementation).
* XML-RPC uses recursion.
* Error handling for XML-RPC and custom Odin faults.
* BA Settings `-ServerString` and `-Credential` added.
* `-SendTo` is now `-Server`, `-BaServerString` is now `-ServerString`, `-Execute` was replaced with native PowerShell `-WhatIf` and `-Confirm`.
* Added `-UseSsl` and `-Port`.
* Base64 class extended.
* Hashtable converts to struct, Ordered hashtable converts to Array with comments.

## 2016.11.24 - Version 1.2.X
* PowerShell module structure
  * Rearranged files
  * Fixed module name
  * Add .psd1 file
* ConvertFrom-OdinApiXml
  * Fix Bug that multiple arrays on the same level will unrolled into a single array
* Invoke-OdinApi
  * Add conversion of output to UTF-8 to support multilanguage characters

## 2016.09.08 - Version 1.0.0
* Base Version