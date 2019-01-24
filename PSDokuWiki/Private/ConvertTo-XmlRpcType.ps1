function ConvertTo-XmlRpcType
{
    <#
        .SYNOPSIS
            Convert Data into XML declared datatype string

        .DESCRIPTION
            Convert Data into XML declared datatype string

        .OUTPUTS
            string

        .PARAMETER InputObject
            Object to be converted to XML string

        .PARAMETER CustomTypes
            Array of custom Object Types to be considered when converting

        .EXAMPLE
            ConvertTo-XmlRpcType "Hello World"
            --------
            Returns
            <value><string>Hello World</string></value>

        .EXAMPLE
            ConvertTo-XmlRpcType 42
            --------
            Returns
            <value><int32>42</int32></value>

        .Notes
            Author   : Oliver Lipkau <oliver@lipkau.net>
            2014-06-05 Initial release
            
            Sourced from Oliver Lipkau's XmlRpc module on powershellgallery
            Modified to use DokuWiki compatible type names (case sensitive etc)
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [AllowNull()]
        [Parameter(
            Position=1,
            Mandatory=$true
        )]
        $InputObject,

        [Parameter()]
        [Array]$CustomTypes
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        $Objects = @('Object')
        $objects += $CustomTypes
    }

    Process
    {
        if ($null -ne $inputObject)
        {
            [string]$Type=$inputObject.GetType().Name
            # [string]$BaseType=$inputObject.GetType().BaseType
        }
        else
        {
            return "<value></value>"
        }

        # Return simple Types
        if (('Double','Int32','Boolean','False') -contains $Type)
        {
            return "<value><$($Type)>$($inputObject)</$($Type)></value>"
        }

        # Encode string to HTML
        if ($Type -eq 'String')
        {
            return "<value><$Type>$([System.Web.HttpUtility]::HtmlEncode($inputObject))</$Type></value>"
        }

        # Int32 must be casted as Int
        if ($Type -eq 'Int16')
        {
            return "<value><int>$inputObject</int></value>"
        }

        if ($type -eq "SwitchParameter")
        {
            return "<value><boolean>$inputObject.IsPresent</boolean></value>"
        }

        # Return In64 as Double
        if (('Int64') -contains $Type)
        {
            return "<value><Double>$inputObject</Double></value>"
        }

        # DateTime
        if('DateTime' -eq $Type)
        {
            return "<value><dateTime.iso8601>$($inputObject.ToString(
            'yyyyMMddTHH:mm:ss'))</dateTime.iso8601></value>"
        }

        # Loop though Array
        if(($inputObject -is [Array]) -or ($Type -eq "List``1"))
        {
            try
            {
                return "<value><array><data>$(
                    [string]::Join(
                        '',
                        ($inputObject | ForEach-Object  {
                            if ($null -ne $_) {
                                ConvertTo-XmlRpcType $_ -CustomTypes $CustomTypes
                            } else {}
                        } )
                    )
                )</data></array></value>"
            }
            catch
            {
                throw
            }
        }

        # Loop though HashTable Keys
        if('Hashtable' -eq $Type)
        {
            return "<value><struct>$(
                [string]::Join(
                    '',
                    ($inputObject.Keys|  Foreach-Object {
                        "<member><name>$($_)</name>$(
                            if ($null -ne $inputObject[$_]) {
                                ConvertTo-XmlRpcType $inputObject[$_] -CustomTypes $CustomTypes
                            } else {
                                ConvertTo-XmlRpcType $null
                            })</member>"
                    } )
                )
            )</struct></value>"
        }

        # Loop though Object Properties
        if(($Objects -contains $Type) -and ($inputObject))
        {
            return "<value><struct>$(
                [string]::Join(
                    '',
                    (
                        ($inputObject | Get-Member -MemberType Properties).Name | Foreach-Object {
                            if ($null -ne $inputObject.$_) {
                                "<member><name>$($_)</name>$(
                                    ConvertTo-XmlRpcType $inputObject.$_ -CustomTypes $CustomTypes
                                )</member>"
                            }
                        }
                    )
                )
            )</struct></value>"
        }

        # XML
        if ('XmlElement','XmlDocument' -contains $Type)
        {
            return $inputObject.InnerXml.ToString()
        }

        # XML
        if ($inputObject -match "<([^<>]+)>([^<>]+)</\\1>")
        {
            return $inputObject
        }
    }

    End
        { Write-Verbose "$($MyInvocation.MyCommand.Name):: Function Ended" }
}