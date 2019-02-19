Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Display Name for the Azure AD App/Service Principal")]
  [string]$appName
)
Write-Output ""
Write-Output "Create Azure AD Service Principal"
Write-Output "Version - 1.0.1"
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
$tenant = Get-AzSubscription -SubscriptionId $subcriptionId
"Tenant/Directory ID - " + $tenant.TenantId | Out-File -Encoding Ascii -FilePath ".\ServicePrincipal.txt" -Append

#Create App Uri
$appUri = "https://$appName.com"

#Create App Secret Key
$appSecret = $(-join ((48..57) + (97..122) | Get-Random -Count 44 | % {[char]$_}) | Out-String -NoNewLine) 
"Service Principal Application Secret - " + $appSecret | Out-File -FilePath ".\ServicePrincipal.txt" -Append
$appSecret = $($appSecret | ConvertTo-SecureString -AsPlainText -Force)

# Create the Azure AD app
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating App Registration..."
$adApplication = New-AzADApplication -DisplayName $appName -HomePage $appUri -IdentifierUris $appUri -Password $appSecret -EndDate 31/12/2299

# Create a Service Principal for the Azure AD App
$servicePrincipal = New-AzADServicePrincipal -ApplicationId $adApplication.ApplicationId

#Sleep for 15 seconds
sleep 15

#Output Required App Information
"Service Principal Application ID - " + $servicePrincipal.ApplicationId | Out-File -FilePath ".\ServicePrincipal.txt" -Append
"Enterprise Application Object ID - " + $servicePrincipal.Id | Out-File -FilePath ".\ServicePrincipal.txt" -Append


Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] App Registration Completed successfully!"
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] IMPORTANT - Please Save Output ServicePrincipal.txt Securely!!!"