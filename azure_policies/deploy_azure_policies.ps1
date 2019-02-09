Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$resubcriptionIdgion,

  [Parameter(Mandatory=$True, HelpMessage="Azure Region to Deploy the Policy to")]
  [string]$region,

  [Parameter(Mandatory=$True, HelpMessage="List of Azure Regions to Allow Resource Creation")]
  [array]$locations,

  [Parameter(Mandatory=$True, HelpMessage="List of Mandatory Tag Names")]
  [array]$tagNames,

  [Parameter(Mandatory=$True, HelpMessage="List of Allowed VM SKUs")]
  [array]$vmSkus
)
Write-Host ""
Write-Host "Deploy Azure Policies"
Write-Host "Version - 1.0.0"
Write-Host "Author - Ryan Froggatt (CloudPea)"
Write-Host ""

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

# Deploy Azure RM "Allowed Location" Policy
$Policy = Get-AzPolicyDefinition | Where-Object {$_.Properties.DisplayName -eq 'Allowed locations' -and $_.Properties.PolicyType -eq 'BuiltIn'}
$AllowedLocations = @{"listOfAllowedLocations"=($locations)}
New-AzPolicyAssignment -Name "Allowed Locations" -PolicyDefinition $Policy -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)" -PolicyParameterObject $AllowedLocations


# Deploy Azure RM "Enforce Tag and its value" Policy
$Policy = Get-AzPolicyDefinition | Where-Object {$_.Properties.DisplayName -eq 'Apply tag and its default value' -and $_.Properties.PolicyType -eq 'BuiltIn'}
$PolicyDefinition = New-Object System.Collections.Generic.List[System.Object]

foreach($tagName in $tagNames){
    write-output $tagName
    $PolicyDefinition.Add(@{
        "policyDefinitionId"= "/providers/Microsoft.Authorization/policyDefinitions/$($Policy.name)";
        "parameters"=@{
            "tagName"=@{ 
                "value"="$tagName";
            };
            "tagValue"=@{
                "value"= "Unknown";
            };
        };
    })
}

New-AzPolicySetDefinition -Name "TagInitiative" -DisplayName "Apply default tags and default values" -Description "Apply default tags and default values" -PolicyDefinition ($PolicyDefinition | ConvertTo-JSON -Compress -Depth 5)
$PolicySet = Get-AzPolicySetDefinition | Where-Object {$_.Name -eq 'TagInitiative'}
Start-Sleep -s 10
New-AzPolicyAssignment -Name "Apply default tags and default values" -PolicySetDefinition $PolicySet -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)" -Sku @{"name"="A1";"tier"="Standard"}


# Deploy Azure RM "Allowed Virtual Machine SKU's" Policy
$vmList = New-Object System.Collections.Generic.List[System.Object]
foreach($vmSku in $vmSkus){
    foreach($vmSize in (Get-AzVMSize -location $region | Where-Object {$_.Name -match $vmSeries}).Name){
        $vmList.Add($vmSize)
    }
}

$AllowedVmSKUs = @{"listOfAllowedSKUs"=($vmList.ToArray())}
$Policy = Get-AzPolicyDefinition | Where-Object {$_.Properties.DisplayName -eq 'Allowed virtual machine SKUs' -and $_.Properties.PolicyType -eq 'BuiltIn'}
New-AzPolicyAssignment -Name "Allowed virtual machine SKUs" -PolicyDefinition $Policy -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)" -PolicyParameterObject $AllowedVmSKUs
