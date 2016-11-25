<#
class Base64
{
    [string]$ItemName

    Base64([string]$String) 
    {
        $this.ItemName = $String
    }

    [string]ToString()
    {
        return $this.ItemName
    }
}
#>

if (!([System.Management.Automation.PSTypeName]'Base64').Type)
{
    Add-Type -Language CSharp -TypeDefinition @"
public class Base64
{
    public string ItemName;

    public Base64(string Str)
    {
        ItemName = Str;
    }

    public override string ToString()
    {
        return ItemName;
    }
}
"@
}

function ConvertFrom-OdinApiXml
{
    <#
        .SYNOPSIS
        convert API XML response to Object
        .DESCRIPTION
        If "-OutputXml" switch was used on Invoke-OdinApi you can then run this to convert the XML
        .EXAMPLE
        ConvertFrom-OdinApiXml -Xml $Xml
        .LINK
        https://github.com/ili101/Invoke-OdinApi
    #>
    [CmdletBinding(HelpURI='https://github.com/ili101/Invoke-OdinApi')]
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        $Xml
    )

    if ($Xml -is [System.Xml.XmlDocument])
    {
        $Xml = $Xml.methodResponse
    }
    if ($Xml.Name -eq 'methodResponse')
    {
        $Xml = $Xml.FirstChild
    }
    if ($Xml.Name -eq 'params')
    {
        $Xml = $Xml.FirstChild
    }
    if ($Xml.Name -eq 'param')
    {
        $Xml = $Xml.FirstChild
    }
    if ($Xml.Name -eq 'value')
    {
        $Xml = $Xml.FirstChild
    }
    if ($Xml.Name -eq 'struct')
    {
        $Response = @{}
        $Xml.member | ForEach-Object -Process {
            $Response.Add($_.name, (ConvertFrom-OdinApiXml -Xml ($_.value)))
        }
        $Response = New-Object -TypeName PSObject -Property $Response
    } 
    elseif($Xml.Name -eq 'array')
    {
        $Response = @()
        $Xml.data.value | ForEach-Object -Process {
            $Response += , (ConvertFrom-OdinApiXml -Xml ($_))
        }
    }
    elseif($Xml.Name -eq 'fault')
    {
        $Response = ConvertFrom-OdinApiXml -Xml ($Xml.value)
        if ($Response.faultCode -eq -1)
        {
            $Response.faultString = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Response.faultString)))            
        }
        Write-Error -Message ('Odin Error: faultCode: "{0}", faultString: "{1}"' -f $Response.faultCode,$Response.faultString) -ErrorAction Stop
    }
    elseif($Xml.Name -eq 'i4')
    {
        [int]$Response = $Xml.InnerXml
    }
    elseif($Xml.Name -eq 'boolean')
    {
        [boolean]$Response = [int]::Parse($Xml.InnerXml)
    }
    else
    {
        $Response = $Xml.InnerXml
    }

    Write-Verbose -Message ($Response | Out-String)
    $Response
}

function Invoke-OdinApi
{
    <#
        .SYNOPSIS
        Execute OA/BA API commands
        .DESCRIPTION
        Execute Odin "Operations Automation" and "Business Automation" API commands
        .EXAMPLE
        Invoke-OdinApi -OA -Method 'pem.statistics.getStatisticsReport' -Parameters @{reports=@(@{name='poaVersion'; value='0'})} -SendTo '123.123.123.123:8440'
        .LINK
        https://github.com/ili101/Invoke-OdinApi
    #>
    [CmdletBinding(HelpURI='https://github.com/ili101/Invoke-OdinApi')]
    param
    (
        # Send Business Automation API command, See http://download.automation.odin.com/oa/7.0/oapremium/portal/en/billing_api_reference/55879.htm for the list of methods and parameters.
        [Parameter(
            ParameterSetName='Business Automation',
            Mandatory=$true, Position=0)]
        [switch]
        $BA,
        # Send Operations Automation API command, See http://download.automation.odin.com/oa/7.0/oapremium/portal/en/operations_api_reference/55879.htm for the list of methods and parameters.
        [Parameter(
            ParameterSetName='Operations Automation',
            Mandatory=$true, Position=0)]
        [switch]
        $OA,
        # The Method name.
        [Parameter(Mandatory=$true, Position=1)]
        [System.String]
        $Method,
        # The methods parameters, Ordered hashtable required for BA, ordered hashtable or a normal hashtable required for OA.
        [Parameter(Mandatory=$true, Position=2)]
        $Parameters,
        # IP to send the call to, if not provided the API request is returned.
        [Parameter(Mandatory=$false, Position=3)]
        [System.String]
        $SendTo = $null,
        # Return the unconverted result XML
        [Parameter(Mandatory=$false, Position=4)]
        [switch]
        $OutputXml
    )

    if ($BA)
    {
        if ($Parameters -isnot [System.Collections.Specialized.OrderedDictionary])
        {
            Write-Error -Message 'Error: Parameters is not an ordered hashtable' -ErrorAction Stop
        }

        # Create The Document
        $RequestXML = New-Object -TypeName xml
        $null = $RequestXML.AppendChild($RequestXML.CreateXmlDeclaration('1.0','UTF-8',$null))
        
        $TempElement = $RequestXML.AppendChild($RequestXML.CreateElement('methodCall'))
            $TempElement.AppendChild($RequestXML.CreateElement('methodName')).InnerText = 'Execute'
            $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('params'))
                $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('param'))
                    $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('value'))
                        $structElement = $TempElement.AppendChild($RequestXML.CreateElement('struct'))
                            $TempElement = $structElement.AppendChild($RequestXML.CreateElement('member'))
                                $TempElement.AppendChild($RequestXML.CreateElement('name')).InnerText = 'Server'
                                $TempElement.AppendChild($RequestXML.CreateElement('value')).InnerText = 'BM'
        
                            $TempElement = $structElement.AppendChild($RequestXML.CreateElement('member'))
                                $TempElement.AppendChild($RequestXML.CreateElement('name')).InnerText = 'Method'
                                $TempElement.AppendChild($RequestXML.CreateElement('value')).InnerText = $Method
        
                            $TempElement = $structElement.AppendChild($RequestXML.CreateElement('member'))
                                $TempElement.AppendChild($RequestXML.CreateElement('name')).InnerText = 'Params'
                                $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('value'))
                                    $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('array'))
                                        $dataElement = $TempElement.AppendChild($RequestXML.CreateElement('data'))
                                            ForEach ($Parameter in $Parameters.GetEnumerator())
                                            {
                                                $null = $dataElement.AppendChild($RequestXML.CreateComment($Parameter.Key))
                                                $TempElement = $dataElement.AppendChild($RequestXML.CreateElement('value'))
                                                    if ($Parameter.Value -is [int])
                                                    {
                                                        $TempElement.AppendChild($RequestXML.CreateElement('i4')).InnerText = $Parameter.Value
                                                    }
                                                    elseif ($Parameter.Value -is [double])
                                                    {
                                                        $TempElement.AppendChild($RequestXML.CreateElement('double')).InnerText = $Parameter.Value
                                                    }
                                                    elseif ($Parameter.Value -is [string])
                                                    {
                                                        $TempElement.InnerText = $Parameter.Value
                                                    }
                                                    else
                                                    {
                                                        Write-Error -Message ('Parameter "{0}" is of unsupported type "{1}"' -f $Parameter.Key,$Parameter.GetType().Name) -ErrorAction Stop
                                                    }
                                            }
    }
    elseif ($OA)
    {
        if ($Parameters -isnot [System.Collections.Hashtable] -and $Parameters -isnot [System.Collections.Specialized.OrderedDictionary] -and $Parameters -isnot [System.Array])
        {
            Write-Error -Message 'Error: Parameters is not a hashtable or array' -ErrorAction Stop
        }

        # Create The Document
        $RequestXML = New-Object -TypeName xml
        $null = $RequestXML.AppendChild($RequestXML.CreateXmlDeclaration('1.0','UTF-8',$null))
        
        $TempElement = $RequestXML.AppendChild($RequestXML.CreateElement('methodCall'))
            $TempElement.AppendChild($RequestXML.CreateElement('methodName')).InnerText = $Method
            $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('params'))
                ForEach ($Parameter in $Parameters)
                {
                        if ($Parameter -isnot [System.Collections.Hashtable] -and $Parameter -isnot [System.Collections.Specialized.OrderedDictionary])
                        {
                            Write-Error -Message 'Error: Parameters array do not contain a hashtable' -ErrorAction Stop
                        }
                    $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('param'))
                        function Set-Members
                        {
                            param ($Parameter = $null)
                            $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('value'))
                                if ($Parameter -is [int])
                                {
                                    $TempElement.AppendChild($RequestXML.CreateElement('int')).InnerText = $Parameter
                                }
                                elseif ($Parameter -is [Int64])
                                {
                                    $TempElement.AppendChild($RequestXML.CreateElement('bigint')).InnerText = $Parameter
                                }
                                elseif ($Parameter -is [string])
                                {
                                    $TempElement.AppendChild($RequestXML.CreateElement('string')).InnerText = $Parameter
                                }
                                elseif ($Parameter -is [Boolean])
                                {
                                    $TempElement.AppendChild($RequestXML.CreateElement('boolean')).InnerText = if ($Parameter) {1} else {0}
                                }
                                elseif ($Parameter -is [Base64])
                                {
                                    $TempElement.AppendChild($RequestXML.CreateElement('base64')).InnerText = $Parameter
                                }
                                elseif ($Parameter -is [System.Collections.Hashtable] -or $Parameter -is [System.Collections.Specialized.OrderedDictionary]) #struct
                                {
                                    $structElement = $TempElement.AppendChild($RequestXML.CreateElement('struct'))
                                        ForEach ($Param in $Parameter.GetEnumerator())
                                        {
                                            Write-Verbose -Message ($Param | Out-String)
                                            $TempElement = $structElement.AppendChild($RequestXML.CreateElement('member'))
                                                $TempElement.AppendChild($RequestXML.CreateElement('name')).InnerText = $Param.Key
                                                Set-Members -Parameter $Param.Value
                                        }
                                }
                                elseif ($Parameter -is [System.Array]) #array
                                {
                                    $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('array'))
                                        $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('data'))
                                            ForEach ($Item in $Parameter)
                                            {
                                                Write-Verbose -Message ($Item | Out-String)
                                                Set-Members -Parameter $Item
                                            }
                                }
                                else
                                {
                                    Write-Error -Message ('Parameter "{0}" is of unsupported type "{1}"' -f $Parameter,$Parameter.GetType().Name) -ErrorAction Stop
                                }
                        }
                    Set-Members -Parameter $Parameter
                }
    }
    if ($SendTo)
    {
        Write-Verbose -Message $RequestXML.InnerXml
        if ($BA) {$Port = '5224'} else {$Port = '8440'}
        $Url = 'http://' + $SendTo + ':' +  $Port
        $ResponseXML = Invoke-RestMethod -Uri $Url -Body $RequestXML -Method Post
        $ResponseXML = [xml][System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($ResponseXML.InnerXml))

        if ($OutputXml)
        {
            $ResponseXML
        }
        else
        {
            ConvertFrom-OdinApiXml -Xml $ResponseXML
        }
    }
    else
    {
        $RequestXML
    }
}
