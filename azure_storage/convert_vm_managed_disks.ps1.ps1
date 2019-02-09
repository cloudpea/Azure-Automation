Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Virtual Machine Name")]
  [string]$vmName,

  [Parameter(Mandatory=$True, HelpMessage="Resource Group Name of the VM")]
  [securestring]$resourceGroupName
)
Write-Output ""
Write-Output "Convert Azure VM to Managed Disks"
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

#Stop Virtual Machine
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Virtual Machine" $vmName
Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Force
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $vmName "has successfully stopped"

#Convert VM to Managed Disks
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converting Virtual Machine" $vmName "to managed disks"
ConvertTo-AzVMManagedDisk -ResourceGroupName $resourceGroupName -VMName $vmName
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converted Virtual Machine" $vmName "to managed disks successfully!"

#Start Virtual Machine
Start-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Virtual Machine" $vm.Name "started successfully"