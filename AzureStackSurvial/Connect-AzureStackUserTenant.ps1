<#
Works for AzureStack 18.11
#>

[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$AzureStackURL,
    [Parameter(Mandatory=$True)]
    [string]$UserTenantFQDN
)

#Read username and paassword so we do not get a prompt
$username = Read-Host 
$password = Read-Host -AsSecureString
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

Add-AzureRMEnvironment -Name "AzureStackUser" -ArmEndpoint $AzureStackURL
$AuthEndpoint = (Get-AzureRmEnvironment -Name "AzureStackUser").ActiveDirectoryAuthority.TrimEnd('/')
$TenantId = (invoke-restmethod "$($AuthEndpoint)/$($UserTenantFQDN)/.well-known/openid-configuration").issuer.TrimEnd('/').Split('/')[-1]
Add-AzureRmAccount -EnvironmentName "AzureStackUser" -TenantId $TenantId -Credential $cred