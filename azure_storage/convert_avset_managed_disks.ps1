Param (
  [Parameter(Mandatory=$True)]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True)]
  [string]$avSetName,

  [Parameter(Mandatory=$True)]
  [securestring]$resourceGroupName
)
Write-Output ""
Write-Output "Convert Azure Availabiltiy Set to Managed Disks"
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

#Convert Availability set to Managed
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Changing Availability set SKU to aligned"

#Try with current number of fault domains
$avSet = Get-AzAvailabilitySet -ResourceGroupName $resourceGroupName -Name $avSetName
Update-AzAvailabilitySet -AvailabilitySet $avSet -Sku Aligned -ErrorAction SilentlyContinue

#If Error Try with 2 Fault Domains
if ($error.Count -gt 0) {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Changing Availability set Fault Domains to 2 as current number is not supported"
$avSet.PlatformFaultDomainCount = 2
Update-AzAvailabilitySet -AvailabilitySet $avSet -Sku Aligned  
}

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Availability set updated successfully"

#Convert each VM disks to managed
$avSet = Get-AzAvailabilitySet -ResourceGroupName $resourceGroupName -Name $avSetName
foreach($vm in $avSet.VirtualMachinesReferences)
{
  #Get VM Object  
  $vm = Get-AzResource -ResourceId $vm.id

  #Stop VM
  Write-Output ""
  Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Virtual Machine -" $vm.Name
  Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Force

  #Convert VM to Managed Disks
  Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converting" $vm.Name "to Managed Disks"
  ConvertTo-AzVMManagedDisk -ResourceGroupName $resourceGroupName -VMName $vm.Name
  Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converted" $vm.Name "to Managed Disks successfully"

  #Start VM
  Start-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name
  Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Virtual Machine" $vm.Name "started successfully"

  #Wait for specified time period before proceeding
  Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting 60 seconds for VM to boot and start application services"
  SLEEP 60
}