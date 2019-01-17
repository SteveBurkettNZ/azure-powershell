# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Tests Enable-AzureRmAlias and Disable-AzureRmAlias
#>
function Test-AzureRmAlias
{
	Disable-AzureRmAlias
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias
	Get-AzureRmSubscription

	Disable-AzureRmAlias -Scope "Process" -Module Az.Accounts
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias -Module Az.Compute, Az.Resources
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias -Scope "Process" -Module Az.Accounts
	Get-AzureRmSubscription

	$PROFILE = New-Object PSObject -Property @{
		CurrentUserAllHosts = Join-Path $PSScriptRoot "CurrentUserProfile.ps1"; 
		AllUsersAllHosts = Join-Path $PSScriptRoot "AllUsersProfile.ps1"
	}

	Disable-AzureRmAlias
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias -Scope "CurrentUser" -Module Az.Accounts
	Get-AzureRmSubscription
	$azureSession = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance
	$file = $azureSession.DataStore.ReadFileAsText($PROFILE.CurrentUserAllHosts)
	
	$expected = 
"`r`n#Begin Azure PowerShell alias import`r`nImport-Module Az.Accounts -ErrorAction SilentlyContinue -ErrorVariable importError"+
"`r`nif (`$importerror.Count -eq 0) { `r`n    Enable-AzureRmAlias -Module Az.Accounts -ErrorAction SilentlyContinue; `r`n}`r`n#End Azure PowerShell alias import"

	$expectedLinux = 
"`n#Begin Azure PowerShell alias import`nImport-Module Az.Accounts -ErrorAction SilentlyContinue -ErrorVariable importError"+
"`nif (`$importerror.Count -eq 0) { `n    Enable-AzureRmAlias -Module Az.Accounts -ErrorAction SilentlyContinue; `n}`n#End Azure PowerShell alias import"
	
	try {
		Assert-AreEqual $file $expected
	} catch {
		Assert-AreEqual $file $expectedLinux
	}

	Enable-AzureRmAlias -Scope "LocalMachine" -Module Az.Accounts
	$file = $azureSession.DataStore.ReadFileAsText($PROFILE.AllUsersAllHosts)
	Assert-AreEqual $file $expected
}
