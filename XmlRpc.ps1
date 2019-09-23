# https://en.wikipedia.org/wiki/XML-RPC
# https://web.archive.org/web/20050911054235/http://ontosys.com/xml-rpc/extensions.php
# https://web.archive.org/web/20050913062502/http://www.xmlrpc.com/spec#update1

class XmlRpcFaultException : Exception {
    XmlRpcFaultException($Message) : base($Message) { }
    XmlRpcFaultException($Message, $InnerException) : base($Message, $InnerException) { }
}

function ConvertTo-XmlRpcMethodCall {
    <#
        .SYNOPSIS
        Create a XML RPC Method Call.

        .DESCRIPTION
        Create a XML RPC Method Call.

        .OUTPUTS
        xml

        .EXAMPLE
        ConvertTo-XmlRpcMethodCall -Name updateName -Params @('oldName', 'newName')
        ----------
        Returns (line split and indentation just for convenience)
        <?xml version=""1.0""?>
        <methodCall>
            <methodName>updateName</methodName>
            <params>
            <param><value><string>oldName</string></value></param>
            <param><value><string>newName</string></value></param>
            </params>
        </methodCall>
    #>
    [CmdletBinding()]
    [OutputType([xml])]
    param(
        # Name of the Method to be called.
        [Parameter(Mandatory)]
        [String]$Method,

        # Parameters to be passed to the Method.
        [Array]$Parameters,

        # How the handle Int64.
        [ValidateSet('Error', 'Int', 'Double', 'BigInt')]
        [String]$Int64Mode = 'Error'
    )

    # Create The Document.
    $RequestXML = [xml]::new()
    $null = $RequestXML.AppendChild($RequestXML.CreateXmlDeclaration('1.0', 'UTF-8', $null))

    $TempElement = $RequestXML.AppendChild($RequestXML.CreateElement('methodCall'))
    $TempElement.AppendChild($RequestXML.CreateElement('methodName')).InnerText = $Method
    $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('params'))
    foreach ($Param in $Parameters) {
        ConvertTo-XmlRpcType -XmlElement $TempElement.AppendChild($RequestXML.CreateElement('param')) -InputObject $Param
    }

    $RequestXML
}
function ConvertTo-XmlRpcType {
    <#
        .SYNOPSIS
        Convert Data into XML declared datatype.

        .DESCRIPTION
        Convert Data into XML declared datatype.

        .NOTES
        Assumed variables from parent scope:
        $RequestXML, $Int64Mode

        .EXAMPLE
        ConvertTo-XmlRpcType "Hello World"
        --------
        Returns
        <value><string>Hello World</string></value>

        .EXAMPLE
        ConvertTo-XmlRpcType 42
        --------
        Returns
        <value><int>42</int></value>
    #>
    [CmdletBinding()]
    param(
        # Object to be converted to XML.
        [AllowNull()]
        [Parameter(Mandatory)]
        $InputObject,

        # XmlElement to add the InputObject to.
        [Parameter(Mandatory)]
        [Xml.XmlElement]$XmlElement
    )

    $TempElement = $XmlElement.AppendChild($RequestXML.CreateElement('value'))
    # if ($null -eq $InputObject) {
    #     $null = $TempElement.AppendChild($RequestXML.CreateElement('nil'))
    # }
    if ($InputObject -is [int] -or $InputObject -is [int16] -or ($InputObject -is [int64] -and $Int64Mode -eq 'Int')) {
        # 'i4' in BA examples.
        $TempElement.AppendChild($RequestXML.CreateElement('int')).InnerText = $InputObject
    }
    elseif ($InputObject -is [Int64] -and $Int64Mode -eq 'BigInt') {
        # OA custom type.
        $TempElement.AppendChild($RequestXML.CreateElement('bigint')).InnerText = $InputObject
    }
    elseif ($InputObject -is [double] -or ($InputObject -is [int64] -and $Int64Mode -eq 'Double')) {
        # Not used in OA.
        $TempElement.AppendChild($RequestXML.CreateElement('double')).InnerText = $InputObject
    }
    elseif ($InputObject -is [string]) {
        $TempElement.AppendChild($RequestXML.CreateElement('string')).InnerText = $InputObject
    }
    elseif ($InputObject -is [Boolean]) {
        $TempElement.AppendChild($RequestXML.CreateElement('boolean')).InnerText = [int]$InputObject
    }
    elseif ($InputObject -is [Base64]) {
        $TempElement.AppendChild($RequestXML.CreateElement('base64')).InnerText = $InputObject
    }
    elseif ($InputObject -is [Collections.Hashtable]) {
        $StructElement = $TempElement.AppendChild($RequestXML.CreateElement('struct'))
        foreach ($Item in $InputObject.GetEnumerator()) {
            $TempElement = $StructElement.AppendChild($RequestXML.CreateElement('member'))
            $TempElement.AppendChild($RequestXML.CreateElement('name')).InnerText = $Item.Key
            ConvertTo-XmlRpcType -InputObject $Item.Value -XmlElement $TempElement
        }
    }
    elseif ($InputObject -is [Array]) {
        $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('array'))
        $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('data'))
        foreach ($Item in $InputObject) {
            ConvertTo-XmlRpcType -InputObject $Item -XmlElement $TempElement
        }
    }
    elseif ($InputObject -is [Collections.Specialized.OrderedDictionary]) {
        # BA Array with comment.
        $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('array'))
        $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('data'))
        foreach ($Item in $InputObject.GetEnumerator()) {
            $null = $TempElement.AppendChild($RequestXML.CreateComment($Item.Key))
            ConvertTo-XmlRpcType -InputObject $Item.Value -XmlElement $TempElement
        }
    }
    else {
        $PSCmdlet.ThrowTerminatingError(
            [Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new(('Parameter "{0}" is of unsupported type "{1}"' -f $InputObject, $InputObject.GetType())),
                'Incompatible Arguments',
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $InputObject
            )
        )
    }
}

function ConvertFrom-XmlRpc {
    <#
        .SYNOPSIS
        Convert API XML response to Object.

        .DESCRIPTION
        Convert API XML response to Object.

        .EXAMPLE
        ConvertFrom-XmlRpc -Xml $Xml.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        $Xml
    )
    if ($Xml -is [Xml.XmlDocument]) {
        if ($ResponseXML = $Xml.methodResponse.fault.value) {
            $ResponseObj = ConvertFrom-XmlRpc -Xml $ResponseXML
            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [XmlRpcFaultException]::new(('XmlRpc Fault: faultCode: "{0}", faultString: "{1}".' -f $ResponseObj.faultCode, $ResponseObj.faultString)),
                    'XmlRpc Fault',
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $ResponseObj
                )
            )
        }
        elseif ($ResponseXML = $Xml.methodResponse.params.param.value) {
            ConvertFrom-XmlRpc -Xml $ResponseXML
        }
        else {
            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [ArgumentException]::new('Xml is not XML-RPC methodResponse'),
                    'Incompatible Arguments',
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $Xml
                )
            )
        }
    }
    elseif ($Xml -is [Xml.XmlElement]) {
        if ($Xml.Name -eq 'value') {
            $Xml = $Xml.FirstChild
        }
        if ($Xml.Name -eq 'struct') {
            $HashTable = @{ }
            foreach ($Member in $Xml.member) {
                $HashTable.Add($Member.name, (ConvertFrom-XmlRpc -Xml $Member.value))
            }
            [PSCustomObject]$HashTable
        }
        elseif ($Xml.Name -eq 'array') {
            , @(foreach ($DataValue in $Xml.data.value) {
                ConvertFrom-XmlRpc -Xml $DataValue
            })
        }
        elseif ($Xml.Name -in 'i4', 'int') {
            [int]$Xml.InnerXml
        }
        elseif ($Xml.Name -eq 'boolean') {
            [bool][int]$Xml.InnerXml
        }
        elseif ($Xml.Name -eq 'double') {
            [Double]$Xml.InnerXml
        }
        elseif ($Xml.Name -eq 'string') {
            $Xml.InnerXml
        }
        else {
            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [ArgumentException]::new('Unknown element: "{0}"' -f $Xml.Name),
                    'Incompatible Arguments',
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $Xml
                )
            )
        }
    }
    else {
        $PSCmdlet.ThrowTerminatingError(
            [Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new('Item isn''t an XML: "{0}"' -f $Xml.GetType()),
                'Incompatible Arguments',
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $Xml
            )
        )
    }
}