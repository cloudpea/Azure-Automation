Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Display Name for the Azure AD App/Service Principal")]
  [string]$appName,

  [Parameter(Mandatory=$True, HelpMessage="API Key for the Service Principal")]
  [securestring]$appSecret,

  [Parameter(Mandatory=$True, HelpMessage="Azure AD Role Definitation to Assign to the App")]
  [string]$roleDefinition
)
Write-Output ""
Write-Output "Create Azure AD Service Principal"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

#Install and Import Az Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name Az -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name Az
    Import-Module -Name Az
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Output ""

#Login to Azure
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Connect-AzAccount
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Output ""

#Select SubscriptionId
while ($subcriptionId.Length -le 35) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $subcriptionId = Read-Host "Please input your Subscription Id"
}
Select-AzSubscription -SubscriptionId $subcriptionId
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Output ""

#Create Output File
"Service Principal Important Information:" | Out-File -FilePath ".\ServicePrincipal.txt"

#Output Tenant ID
$tenant = Get-AzSubscription -SubscriptionId $SubId
"Tenant Directory ID - " + $tenant.TenantId | Out-File -Encoding Ascii -FilePath ".\ServicePrincipals.txt" -Append

#Values for the Azure AD App:
$appUri = "https://$appName.com"

# Create the Azure AD app
$adApplication = New-AzADApplication -DisplayName $appName -HomePage $appUri -IdentifierUris $appUri -Password $appSecret

# Create a Service Principal for the Azure AD App
$servicePrincipal = New-AzADServicePrincipal -ApplicationId $adApplication.ApplicationId

#Sleep for 15 seconds
SLEEP 15

# Assign the RBAC role to the Service Principal
$appRoleAssignment = New-AzRoleAssignment -RoleDefinitionName $roleDefinition -ServicePrincipalName $adApplication.ApplicationId.Guid

#Output Required App Information
"Application ID - " + $servicePrincipal.ApplicationId | Out-File -FilePath ".\ServicePrincipals.txt" -Append

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] App Registration Completed successfully!"