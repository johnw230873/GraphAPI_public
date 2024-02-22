


param (
    [Parameter(Mandatory=$true )]
    [string]
    $applicationId,
    [Parameter(Mandatory=$true )]
    [string]
    $clientSecret,
    [Parameter(Mandatory=$true )]
    [string]
    $aadTenantId,
    [Parameter(Mandatory=$true )]
    [string]
    $DisplayNameOfMI  



)

Import-Module AzureAD.Standard.Preview

$securePassword = $clientSecret| ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($applicationId, $SecurePassword)
Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId $aadTenantId

$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com")
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net")
Write-Host "Connected to AZ Account"

# Login to Azure AD
Write-Host "Connecting to Azure AD..."
Connect-AzureAD -AadAccessToken $aadToken.AccessToken -AccountId $context.Account.Id -TenantId $context.tenant.id -MsAccessToken $graphToken.AccessToken
Write-Host "Connected to Azure AD"


$GraphAppId = "00000003-0000-0000-c000-000000000000" 
$PermissionNames = @("mail.readbasic", "mail.send")

$MSI = (Get-AzureADServicePrincipal -Filter "displayName eq '$DisplayNameOfMI'")

Start-Sleep -Seconds 20

$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"
foreach ($PermissionName in $PermissionNames) {
  $AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"}
  New-AzureAdServiceAppRoleAssignment -ObjectId $MSI.ObjectId -PrincipalId $MSI.ObjectId -ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id

}
