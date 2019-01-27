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
			$APIResponse = Invoke-DokuApiCall -DokuSession $DokuSession -MethodName 'wiki.getPageInfo' -MethodParameters @($PageName)
			if ($APIResponse.CompletedSuccessfully -eq $true) {
				$ArrayValues = ($APIResponse.XMLPayloadResponse | Select-Xml -XPath "//struct").Node.Member.Value.Innertext
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
			} elseif ($null -eq $APIResponse.ExceptionMessage) {
				Write-Error "Fault code: $($APIResponse.FaultCode) - Fault string: $($APIResponse.FaultString)"
			} else {
				Write-Error "Exception: $($APIResponse.ExceptionMessage)"
			}
		} # foreach
	} # process

	end {

	} # end
}