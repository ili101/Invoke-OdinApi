$ErrorActionPreference = 'Stop'
class XmlRpcOdinFaultException : Exception {
    XmlRpcOdinFaultException($Message) : base($Message) { }
    XmlRpcOdinFaultException($Message, $InnerException) : base($Message, $InnerException) { }
}

function Invoke-OdinApi {
    <#
        .SYNOPSIS
        Execute OA/BA API commands.
        .DESCRIPTION
        Execute Odin "Operations Automation" and "Business Automation" API commands.
        .EXAMPLE
        Invoke-OdinApi -OA -Method 'pem.statistics.getStatisticsReport' -Parameters @{reports=@(@{name='poaVersion'; value='0'})} -Server '123.123.123.123'
        .LINK
        https://github.com/ili101/Invoke-OdinApi
    #>
    [CmdletBinding(HelpURI = 'https://github.com/ili101/Invoke-OdinApi', SupportsShouldProcess, ConfirmImpact = 'Low')]
    param
    (
        # Send Business Automation API command.
        [Parameter(ParameterSetName = 'Business Automation', Mandatory)]
        [switch]$BA,

        # Send Operations Automation API command.
        [Parameter(ParameterSetName = 'Operations Automation', Mandatory)]
        [switch]$OA,

        # The Method name.
        [Parameter(Mandatory)]
        [String]$Method,

        # The methods parameters, Ordered hashtable required for BA, ordered hashtable or a normal hashtable required for OA.
        $Parameters,

        # IP to send the call to, if not provided the API XML request is returned.
        [String]$Server,

        # The server port.
        [Int]$Port,

        # Use https.
        [Switch]$UseSsl,

        # Return the unconverted result XML.
        [Switch]$OutputXml,

        # Add MD5 Order Signature for "OrderStatusChange_API", Require -Server and "OrderID" in the -Parameters.
        [Parameter(ParameterSetName = 'Business Automation')]
        [Switch]$AddSignature,

        # Language.
        [Parameter(ParameterSetName = 'Business Automation')]
        [String]$language,

        # Billing executing engine.
        [Parameter(ParameterSetName = 'Business Automation')]
        [String]$ServerString = 'BM',

        # Billing Credentials.
        [Parameter(ParameterSetName = 'Business Automation')]
        [PSCredential]$Credential
    )
    # if ($Parameters -isnot [Collections.Hashtable] -and $Parameters -isnot [Collections.Specialized.OrderedDictionary] -and $Parameters -isnot [System.Array]) {
    #     $PSCmdlet.ThrowTerminatingError(
    #         [Management.Automation.ErrorRecord]::new(
    #             [ArgumentException]::new('Parameters is not a hashtable or array'),
    #             'Incompatible Arguments',
    #             [Management.Automation.ErrorCategory]::InvalidArgument,
    #             $Parameters
    #         )
    #     )
    # }

    $RequestXML = if ($BA) {
        $WrapperParameters = @{
            Server = $ServerString
            Method = $Method
        }
        if ($Parameters) {
            $WrapperParameters['Params'] = $Parameters
        }
        if ($Language) {
            $WrapperParameters['Lang'] = $Language
        }
        if ($Credential) {
            $WrapperParameters['Username'] = $Credential.UserName
            $WrapperParameters['Password'] = $Credential.GetNetworkCredential().Password
        }
        if ($AddSignature) {
            if (!$Server) {
                $PSCmdlet.ThrowTerminatingError(
                    [Management.Automation.ErrorRecord]::new(
                        [ArgumentException]::new('-AddSignature require -Server'),
                        'Incompatible Arguments',
                        [Management.Automation.ErrorCategory]::InvalidArgument,
                        $Server
                    )
                )
            }
            if ($Parameters['OrderID'] -isnot [int]) {
                $PSCmdlet.ThrowTerminatingError(
                    [Management.Automation.ErrorRecord]::new(
                        [ArgumentException]::new('-AddSignature require "OrderID" in the -Parameters'),
                        'Incompatible Arguments',
                        [Management.Automation.ErrorCategory]::InvalidArgument,
                        $Parameters
                    )
                )
            }
            $GetOrder_API = Invoke-OdinApi -BA -Method 'GetOrder_API' -Parameters ([ordered]@{ 'OrderID' = $Parameters['OrderID'] }) -Server $Server

            $OrderID = $GetOrder_API.Result[0][0]
            $OrderNumber = $GetOrder_API.Result[0][1].Trim()
            $CreationTime = $GetOrder_API.Result[0][6]
            $Total = '{0} {1:N2}' -f $GetOrder_API.Result[0][17], $GetOrder_API.Result[0][8]
            $Comments = $GetOrder_API.Result[0][12].Trim()
            $SignatureString = @($OrderID, $OrderNumber, $CreationTime, $Total, $Comments) -join ''
            Write-Verbose -Message "MD5 Signature String: $SignatureString"

            $Md5 = [Security.Cryptography.MD5CryptoServiceProvider]::new()
            $Utf8 = [Text.UTF8Encoding]::new()
            $SignatureMd5 = [BitConverter]::ToString($Md5.ComputeHash($Utf8.GetBytes($SignatureString))).ToLower() -replace '-', ''
            Write-Verbose -Message ("MD5 Signature: $SignatureMd5")
            $Parameters.Add('Signature', $SignatureMd5)
        }
        ConvertTo-XmlRpcMethodCall -Method 'Execute' -Parameters $WrapperParameters -Int64Mode 'Error'
    }
    elseif ($OA) {
        if ($PSBoundParameters.ContainsKey('Parameters')) {
            ConvertTo-XmlRpcMethodCall -Method $Method -Int64Mode 'BigInt' -Parameters $Parameters
        }
        else {
            ConvertTo-XmlRpcMethodCall -Method $Method -Int64Mode 'BigInt'
        }
    }

    if ($Server -and $PSCmdlet.ShouldProcess($Server, ('Execute the "{0}" API' -f $Method))) {
        if (!$PSBoundParameters.ContainsKey('Int')) {
            if ($BA) { $Port = '5224' } else { $Port = '8440' }
        }
        if ($UseSsl) {
            $Url = 'https://' + $Server + ':' + $Port
        }
        else {
            $Url = 'http://' + $Server + ':' + $Port
        }

        $ResponseXML = Invoke-RestMethod -Uri $Url -Body $RequestXML -Method 'Post'
        $ResponseXML = [Xml][System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($ResponseXML.InnerXml))

        if ($OutputXml) {
            $ResponseXML
        }
        elseif ($BA) {
            ConvertFrom-OdinApiXml -Xml $ResponseXML -BA
        }
        elseif ($OA) {
            ConvertFrom-OdinApiXml -Xml $ResponseXML -OA
        }
    }
    else {
        $RequestXML
    }
}
function ConvertFrom-OdinApiXml {
    <#
        .SYNOPSIS
        Convert API XML response to Object.

        .DESCRIPTION
        If "-OutputXml" switch was used on Invoke-OdinApi you can then run this to convert the XML.

        .EXAMPLE
        ConvertFrom-XmlRpc -Xml $Xml -BA

        .LINK
        https://github.com/ili101/Invoke-OdinApi
    #>
    [CmdletBinding(HelpURI = 'https://github.com/ili101/Invoke-OdinApi')]
    param
    (
        [Parameter(Mandatory)]
        $Xml,

        # Decode Business Automation XML.
        [Parameter(ParameterSetName = 'Business Automation', Mandatory)]
        [switch]$BA,

        # Decode Operations Automation XML.
        [Parameter(ParameterSetName = 'Operations Automation', Mandatory)]
        [switch]$OA
    )

    if ($BA) {
        try {
            ConvertFrom-XmlRpc -Xml $Xml
        }
        catch [XmlRpcFaultException] {
            $ResponseObj = $_.TargetObject
            try {
                $ResponseObj.faultString = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($ResponseObj.faultString))
            }
            catch { }

            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [XmlRpcOdinFaultException]::new(('XmlRpc Odin Fault: faultCode: "{0}", faultString: "{1}".' -f $ResponseObj.faultCode, $ResponseObj.faultString)),
                    'XmlRpc Odin Fault',
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $ResponseObj
                )
            )
        }
    }
    else {
        $ResponseObj = ConvertFrom-XmlRpc -Xml $Xml
        if ($ResponseObj.status -ne 0) {
            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [XmlRpcOdinFaultException]::new(
                        ('XmlRpc Odin Fault: status: "{0}", error_code: "{1}", extype_id: "{2}", module_id: "{3}", error_message: "{4}".' -f @(
                                $ResponseObj.status,
                                $ResponseObj.error_code,
                                $ResponseObj.extype_id,
                                $ResponseObj.module_id,
                                $ResponseObj.error_message
                            ))),
                    'XmlRpc Odin Fault',
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $ResponseObj
                )
            )
        }
        else {
            $ResponseObj
        }
    }
}