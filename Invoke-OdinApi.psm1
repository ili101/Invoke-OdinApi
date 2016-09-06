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

function Invoke-OdinApi
{
    <#
        .SYNOPSIS
        Execute OA/BA API commands
        .DESCRIPTION
        Execute Odin "Operations Automation" and "Business Automation" API commands
        .EXAMPLE
        Get-Something
    #>
    [CmdletBinding()]
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
        # IP:Port to send the call to, if not provided the API request is returned.
        [Parameter(Mandatory=$false, Position=3)]
        [System.String]
        $SendTo = $null
    )

    if ($BA)
    {
        if ($Parameters -isnot [System.Collections.Specialized.OrderedDictionary])
        {
            Write-Error -Message 'Error: ParametersHash is not an ordered hashtable' -ErrorAction Stop
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
        if ($SendTo)
        {
            Write-Verbose -Message $RequestXML.InnerXml
            $Url = 'http://' + $SendTo
            $ResponseXML = Invoke-RestMethod -Uri $Url -Body $RequestXML -Method Post

            if ($ResponseXML.methodResponse.fault)
            {
                $Base64 = $ResponseXML.selectsinglenode("methodResponse/fault/value/struct/member[name='faultString']/value").string
                Write-Error -Message ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64)))
            }
            elseif ($Status = $ResponseXML.selectsinglenode("methodResponse/params/param/value/struct/member[name='Result']/value/array/data/value/struct/member[name='Status']/value").string)
            {
                $Status
            }
            else
            {
                $ResponseXML
            }
        }
        else
        {
            $RequestXML
        }
    }
    elseif ($OA)
    {
        if ($Parameters -isnot [System.Collections.Hashtable] -and $Parameters -isnot [System.Collections.Specialized.OrderedDictionary])
        {
            Write-Error -Message 'Error: ParametersHash is not a hashtable' -ErrorAction Stop
        }

        # Create The Document
        $RequestXML = New-Object -TypeName xml
        $null = $RequestXML.AppendChild($RequestXML.CreateXmlDeclaration('1.0','UTF-8',$null))
        
        $TempElement = $RequestXML.AppendChild($RequestXML.CreateElement('methodCall'))
            $TempElement.AppendChild($RequestXML.CreateElement('methodName')).InnerText = $Method
            $TempElement = $TempElement.AppendChild($RequestXML.CreateElement('params'))
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
                Set-Members -Parameter $Parameters
        if ($SendTo)
        {
            Write-Verbose -Message $RequestXML.InnerXml
            $Url = 'http://' + $SendTo
            $ResponseXML = Invoke-RestMethod -Uri $Url -Body $RequestXML -Method Post
            $ResponseXML
        }
        else
        {
            $RequestXML
        }
    }
}
