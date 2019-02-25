Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,
  [Parameter(Mandatory=$True, HelpMessage="The Name of the first Tag to export")]
  [string]$tagKey1,
  [Parameter(Mandatory=$True, HelpMessage="The Name of the second Tag to export")]
  [string]$tagKey2,
  [Parameter(Mandatory=$True, HelpMessage="The Name of the third Tag to export")]
  [string]$tagKey3,
  [Parameter(Mandatory=$True, HelpMessage="The Name of the fourth Tag to export")]
  [string]$tagKey4
)
Write-Output ""
Write-Output "Get Azure Resource Tags"
Write-Output "Version 1.0.0"
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

#Set CSV Headers and Path
Write-Output ""
"""Resource Name"",""Resource Type"",""Location"",""$tagKey1 Tag"",""$tagKey2 Tag"",""$tagKey3 Tag"",""$tagKey4 Tag""" | Out-File -Encoding ASCII -FilePath ".\azure_resource_tags.csv"


Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering Resource Tags..."
#Get Resource Tags
foreach($Resource in Get-AzResource) {
    Write-Output ("Processing Resource - "+$Resource.Name)
    #Write Resource and Tags to CSV
    """"+$Resource.Name+""","""+$Resource.ResourceType+""","""+$Resource.Location+""","""+$Resource.Tags.$tagKey1+""","""+$Resource.Tags.$tagKey2+""","""+$Resource.Tags.$tagKey3+""","""+$Resource.Tags.$tagKey4+"""" | Out-File -Encoding ASCII -FilePath ".\azure_resource_tags.csv" -Append
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Resource Tags Gathered Successfully!"

