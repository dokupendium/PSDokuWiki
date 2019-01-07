﻿function Get-DokuPageInfo {
<#
	.SYNOPSIS
		Returns information about a Wiki page

	.DESCRIPTION
		Returns information about a Wiki page

	.PARAMETER DokuSession
		The DokuSession (generated by New-DokuSession) from which to get the page info

	.PARAMETER FullName
		The full page name for which to return the data, including namespaces

	.EXAMPLE
		PS C:\> $PageInfo = Get-DokuPageInfo -DokuSession $DokuSession -FullName "namespace:namespace:page"

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
				   HelpMessage = 'The DokuSession from which to get the page info')]
		[ValidateNotNullOrEmpty()]
		[psobject]$DokuSession,
		[Parameter(Mandatory = $true,
				   Position = 2,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   HelpMessage = 'The full page name for which to return the data')]
		[ValidateNotNullOrEmpty()]
		[string[]]$FullName
	)

	begin {

	} # begin

	process {
		foreach ($PageName in $FullName) {
			$payload = (ConvertTo-XmlRpcMethodCall -Name "wiki.getPageInfo" -Params $PageName) -replace "String", "string"
			if ($DokuSession.SessionMethod -eq "HttpBasic") {
				$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop
			} else {
				$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop -WebSession $DokuSession.WebSession
			}
			$ArrayValues = ([xml]$httpResponse.Content | Select-Xml -XPath "//struct").Node.Member.Value.Innertext
			$PageObject = New-Object PSObject -Property @{
				FullName = $PageName
				LastModified = Get-Date -Date ($ArrayValues[1])
				Author = $ArrayValues[2]
				VersionTimestamp = $ArrayValues[3]
				PageName = ($PageName -split ":")[-1]
				ParentNamespace = ($PageName -split ":")[-2]
				RootNamespace = ($PageName -split ":")[0]
			}
			$PageObject
		} # foreach
	} # process

	end {

	} # end
}