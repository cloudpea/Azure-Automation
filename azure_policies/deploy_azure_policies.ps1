Param (
  [Parameter(Mandatory=$True)]
  [string]$region,

  [Parameter(Mandatory=$True)]
  [array]$locations,

  [Parameter(Mandatory=$True)]
  [array]$tagNames,

  [Parameter(Mandatory=$True)]
  [array]$vmSkus
)
Write-Host ""
Write-Host "Deploy Azure Policies"
Write-Host "Version - 1.0.0"
Write-Host "Author - Ryan Froggatt (CloudPea)"
Write-Host ""


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
