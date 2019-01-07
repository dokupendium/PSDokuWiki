﻿function Get-DokuPageAcl {
<#
	.SYNOPSIS
		Returns the permission of the given wikipage

	.DESCRIPTION
		Returns the permission of the given wikipage

	.PARAMETER DokuSession
		The DokuSession (generated by New-DokuSession) from which to get Acl

	.PARAMETER FullName
		The full page name for which to return the ACL

	.EXAMPLE
		PS C:\> $PageACL = Get-DokuPageAcl -DokuSession $DokuSession -FullName "namespace:namespace:page"

	.OUTPUTS
		System.Management.Automation.PSObject

	.NOTES
		AndyDLP - 2018-05-26
#>

	[CmdletBinding()]
	[OutputType([psobject])]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1,
				   HelpMessage = 'The DokuSession from which to get Acl')]
		[ValidateNotNullOrEmpty()]
		[psobject]$DokuSession,
		[Parameter(Mandatory = $true,
				   Position = 2,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   HelpMessage = 'The full page name for which to return the ACL')]
		[ValidateNotNullOrEmpty()]
		[string[]]$FullName
	)

	begin {

	} # begin

	process {
		foreach ($PageName in $FullName) {
			$payload = (ConvertTo-XmlRpcMethodCall -Name "wiki.aclCheck" -Params @($PageName)) -replace "String", "string"
			if ($DokuSession.SessionMethod -eq "HttpBasic") {
				$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop
			} else {
				$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop -WebSession $DokuSession.WebSession
			}

			$PageObject = New-Object PSObject -Property @{
				FullName = $PageName
				Acl = [int]([xml]$httpResponse.Content | Select-Xml -XPath "//value/int").Node.InnerText
				PageName = ($PageName -split ":")[-1]
				ParentNamespace = ($PageName -split ":")[-2]
				RootNamespace = ($PageName -split ":")[0]
			}
			$PageObject
		}
	} # process

	end {

	} # end
}