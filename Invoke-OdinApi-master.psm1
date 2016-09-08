Get-ChildItem -Path $PSScriptRoot | Unblock-File
Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object{ . $_.FullName }

Export-ModuleMember -Function Format-Xml
Export-ModuleMember -Function Invoke-OdinApi
Export-ModuleMember -Function ConvertFrom-OdinApiXml