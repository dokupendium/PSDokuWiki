﻿function Get-DokuPageList {
<#
	.SYNOPSIS
		Gets an array of all pages from an instance of DokuWiki.

	.DESCRIPTION
		Gets an array of all pages from an instance of DokuWiki.

	.PARAMETER DokuSession
		The DokuSession (generated by New-DokuSession) from which to get the page list.

	.EXAMPLE
		PS C:\> $AllPages = Get-DokuPageList -DokuSession $DokuSession

	.EXAMPLE
		PS C:\> $AllPages = Get-DokuPageList -DokuSession $DokuSession

	.OUTPUTS
		System.Management.Automation.PSObject[]

	.NOTES
		AndyDLP - 2018-05-26
#>

	[CmdletBinding()]
	[OutputType([psobject[]])]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   HelpMessage = 'The DokuSession from which to get the page list')]
		[ValidateScript({ ($null -ne $_.WebSession) -or ($_.Headers.Keys -contains "Authorization") })]
		[PSObject]$DokuSession
	)

	begin {

	} # begin

	process {
		$httpResponse = Invoke-DokuApiCall -DokuSession $DokuSession -MethodName 'dokuwiki.getPagelist' -MethodParameters @()
		$MemberNodes = ([xml]$httpResponse.Content | Select-Xml -XPath "//struct").Node
		foreach ($node in $MemberNodes) {
			$PageObject = New-Object PSObject -Property @{
				FullName = (($node.member)[0]).value.string
				Revision = (($node.member)[1]).value.int
				ModifiedTime = (($node.member)[2]).value.int
				Size = (($node.member)[3]).value.int
				PageName = (((($node.member)[0]).value.string) -split ":")[-1]
				ParentNamespace = (((($node.member)[0]).value.string) -split ":")[-2]
				RootNamespace = (((($node.member)[0]).value.string) -split ":")[0]
			}
			[array]$AllDokuwikiPages = $AllDokuwikiPages + $PageObject
		}
		$AllDokuwikiPages
	} # process

	end {

	} # end
}