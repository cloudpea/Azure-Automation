Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$SubscriptionId,

  [Parameter(Mandatory=$True, HelpMessage="The Azure Region to Deploy to")]
  [string]$Location,

  [Parameter(Mandatory=$True, HelpMessage="Name of the Azure Resource Group to Deploy to")]
  [string]$ResourceGroup,

  [Parameter(Mandatory=$True, HelpMessage="Name for the ARM Deployment")]
  [string]$DeploymentName,

  [Parameter(Mandatory=$True, HelpMessage="File path to the ARM Deployment File")]
  [string]$DeploymentFilePath,

  [Parameter(Mandatory=$True, HelpMessage="File path to the ARM Paramaters File")]
  [string]$ParametersFilePath
)
Write-Output ""
Write-Output "Azure ARM Deployment"
Write-Output "Version 1.0.0"
Write-Output ""
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
while ($SubscriptionId.Length -le 35) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $SubscriptionId = Read-Host "Please input your Subscription Id"
}
Select-AzSubscription -SubscriptionId $SubscriptionId
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Output ""

# New or Existing Resource Group
while ($RGCheck -notin ("Y", "N")) {
    $RGCheck = Read-Host "Are you deploying to a new Resource Group (Y / N)"
    $RGCheck = $RGCheck.ToUpper()
}
if ($RGCheck -eq "Y") {
    # Create Resource Group
    $Location = $Location.ToLower()
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
}

#Deploy ARM Template Resources
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Deploying Azure Resources..."
New-AzResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroup `
-TemplateFile $DeploymentFilePath `
-TemplateParameterFile $ParametersFilePath
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Deployment of Azure Resources Completed Successfully!"