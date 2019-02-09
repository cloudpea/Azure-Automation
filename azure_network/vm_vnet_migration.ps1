Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Azure Region Location - westeurope, ukwest")]
  [string]$location,

  [Parameter(Mandatory=$True, HelpMessage="Prefix for Destination Availability Set")]
  [string]$prefix,

  [Parameter(Mandatory=$True, HelpMessage="Name of the Virtual Machine to Migrate")]
  [string]$sourceVM,

  [Parameter(Mandatory=$True, HelpMessage="Resource Group Name of the Virtual Machine to Migrate")]
  [string]$sourceResourceGroup,

  [Parameter(Mandatory=$True, HelpMessage="Name of the Destination Virtual Network")]
  [string]$destinationVnet,

  [Parameter(Mandatory=$True, HelpMessage="Name of the Destination Subnet")]
  [string]$destinationSubnet,

  [Parameter(Mandatory=$True, HelpMessage="Resource Group Name of the Destination Virtual Network")]
  [string]$destinationResourceGroup,
)
Write-Output ""
Write-Output "Azure Windows VM vNet Migration"
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


# Create Destination Subnet Object
$destSubnet = (Get-AzVirtualNetwork -Name $destinationVnet -ResourceGroupName $destinationResourceGroup).Subnets | `
Where-Object {$_.Id -like "*$destinationSubnet"}
Write-Output ""


## Get Source VM Config
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering Source VM Configuration..."
$sourceVM = Get-AzVM -Name $sourceVM -ResourceGroupName $sourceResourceGroup
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Source VM Config Gathered Successfully!"
Write-Output ""


## Create the Destination Virtual Machine Config
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Destination VM Config..."
# Check for Availability Set Configuration
if ($null -ne $sourceVM.AvailabilitySetReference.Id)
{
    #Create VM Config with Availablity Set Configuration
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Checking if Availability Set already exists"
    $sourceAvSet = Get-AzAvailabilitySet -Name ($sourceVM.AvailabilitySetReference.Id).Split('/')[8] -ResourceGroupName ($sourceVM.AvailabilitySetReference.Id).Split('/')[4]
    # Create Destination Availability Set Name
    $destAvSetName = ($prefix + $sourceAvSet.Name)
    while ($destAvSetName.Length -gt 15)
    {
        $prefix = Read-Host "Destination Availbility Set name is greater than 15 characters, please enter a different prefix"
        $destAvSetName = ($prefix + $sourceAvSet.Name)
    }
    # Check if Availability Set already Exists
    $destAvSet = Get-AzAvailabilitySet -Name $destAvSetName -ResourceGroupName $sourceAvSet.ResourceGroupName -ErrorVariable avSetError -ErrorAction SilentlyContinue
    if ($avSetError)
    {
        # Create Destination Availability Set
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] No existing Availability Set Creating New Set for Virtual Machine..."
        $destAvSet = New-AzAvailabilitySet -Location $sourceAvSet.Location -Name $destAvSetName `
        -ResourceGroupName $sourceAvSet.ResourceGroupName `
        -Sku $sourceAvSet.Sku `
        -PlatformFaultDomainCount $sourceAvSet.PlatformFaultDomainCount `
        -PlatformUpdateDomainCount $sourceAvSet.PlatformUpdateDomainCount
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] New Availability Set Created Successfully!"
        Write-Output ""
    } else 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] An Existing Availabiltiy Set Already Exists."
        Write-Output ""
    }

    # Create the VM Config Object
    $destVM = New-AzVMConfig -VMName $sourceVM.Name -VMSize $sourceVM.HardwareProfile.VmSize -AvailabilitySetID $destAvSet.Id -Tags $sourceVM.Tags

} else 
{
    # Create VM Config without Availability Set
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] No Availability Set Required"
    
    # Create the VM Config Object
    $destVM = New-AzVMConfig -VMName $sourceVM.Name -VMSize $sourceVM.HardwareProfile.VmSize -Tags $sourceVM.Tags
    Write-Output ""
}

# Create Network Interface Config
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Configuring the VM Network Interface"
$newIPconfig = New-AzNetworkInterfaceIpConfig -Name ($sourceVM.Name +"-IpConfig1") -PrivateIpAddressVersion IPv4 -SubnetId $destSubnet.Id
$destNIC = New-AzNetworkInterface -Name ($sourceVM.Name + "-NIC1") -ResourceGroupName $sourceResourceGroup -Location $location -IpConfiguration $newIPconfig 
$destVM = Add-AzVMNetworkInterface -VM $destVM -Id $destNIC.Id
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] VM Network Interface Configured Successfully!"
Write-Output ""


# Prompt to Begin Disk Migration
$migrate = Read-Host "Please confirm if you are aready to proceed with the migration (Y \ N)"
while ($migrate -ne "Y") 
{
    $migrate = Read-Host "Please confirm when you are ready to proceed with the migration by entering Y"
}


## Check If VM is using Managed or Unmanaged Disks
if ($null -ne $sourceVM.StorageProfile.OsDisk.ManagedDisk) 
{
    ## Managed Disk Migration
    Write-Output ""
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Starting Managed Disk Migration"

    #Stop Source Azure Virtual Machine
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Source Virtual Machine..."
    Stop-AzVM -Name $sourceVM.Name -ResourceGroupName $sourceVM.ResourceGroupName -Force
    while ((Get-AzVM -Status -Name $sourceVM.Name -ResourceGroupName $sourceVM.ResourceGroupName).Statuses[1].DisplayStatus -ne "VM deallocated") 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Source VM currently shutting down sleeping for 10 Seconds."
        Start-Sleep -Seconds 10
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Source VM is now in a Stopped State."
    Write-Output ""

    # Delete Source VM
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Deleting Source VM..."
    Remove-AzVM -Name $sourceVM.Name -ResourceGroupName $sourceVM.ResourceGroupName -Force
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Source VM Deleted Successfully!"
    Write-Output ""

    # Create OS Disk Config for Managed Disk
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Managed Disk Config for VM Operating System..."
    $destVM = Set-AzVMOSDisk -VM $destVM -ManagedDiskId $sourceVM.StorageProfile.OsDisk.ManagedDisk.Id -CreateOption Attach -Windows
    $destVM = Set-AzVMBootDiagnostics -VM $destVM -disable
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Managed Disk Config Created Successfully!"
    Write-Output ""

    # Create Destination Virtual Machine
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Destination Virtual Machine is now being provisioned..."
    $destVM = New-AzVM -ResourceGroupName $sourceResourceGroup -Location $location -VM $destVM -LicenseType "Windows_Server" -ErrorVariable vmError -ErrorAction SilentlyContinue
    if ($vmError) 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] An error occured during the VM creation please check the destination VM is in a running state before proceeding."
        Write-Output ""
    } else 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Destination VM Created Successfully!"
        Write-Output ""
    }

    # Get Latest Destination VM Config
    $destVM = Get-AzVM -Name $sourceVM.Name -ResourceGroupName $sourceResourceGroup

    #Stop Destination Azure Virtual Machine
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Destination Virtual Machine..."
    Stop-AzVM -Name $destVM.Name -ResourceGroupName $destVM.ResourceGroupName -Force
    while ((Get-AzVM -Status -Name $destVM.Name -ResourceGroupName $destVM.ResourceGroupName).Statuses[1].DisplayStatus -ne "VM deallocated") 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] VM currently shutting down sleeping for 10 Seconds."
        Start-Sleep -Seconds 10
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Destination Virtual Machine is now in a stopped state"
    Write-Output ""

    # Migrate Data Disks from Source VM to Destination VM
    if ($null -ne $sourceVM.StorageProfile.DataDisks) 
    {
        foreach ($Disk in $sourceVM.StorageProfile.DataDisks) 
        {
            Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding " + $Disk.Name + " to Destination VM")
            $DataDisk = $null
            $DataDisk = Get-AzDisk -DiskName $Disk.Name -ResourceGroupName $sourceVM.ResourceGroupName
            $destVM = Add-AzVMDataDisk -VM $destVM -Name $DataDisk.Name -ManagedDiskId $DataDisk.Id -Lun $Disk.Lun -CreateOption Attach
            Update-AzVM -ResourceGroupName $destVM.ResourceGroupName -VM $destVM
            Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] " + $Disk.Name + " Added Successfully!")
            Write-Output ""
        }
    }
} else 
{
    ## Unmanaged Disk Migration
    Write-Output ""
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Starting Unmanaged Disk Migration"

    #Stop Source Azure Virtual Machine
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Source Virtual Machine..."
    Stop-AzVM -Name $sourceVM.Name -ResourceGroupName $sourceVM.ResourceGroupName -Force
    while ((Get-AzVM -Status -Name $sourceVM.Name -ResourceGroupName $sourceVM.ResourceGroupName).Statuses[1].DisplayStatus -ne "VM deallocated") 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Source VM currently shutting down sleeping for 10 Seconds."
        Start-Sleep -Seconds 10
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Source VM is now in a Stopped State."
    Write-Output ""

    # Delete Source VM
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Deleting Source VM..."
    Remove-AzVM -Name $sourceVM.Name -ResourceGroupName $sourceVM.ResourceGroupName -Force
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Source VM Deleted Successfully!"
    Write-Output ""

    # Create OS Disk Config for Unmanaged Disk
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Unmanaged Disk Config for VM Operating System..."
    $destVM = Set-AzVMOSDisk -VM $destVM -Name $sourceVM.StorageProfile.OsDisk.Name -VhdUri $sourceVM.StorageProfile.OsDisk.Vhd.Uri -CreateOption Attach -Windows
    $destVM = Set-AzVMBootDiagnostics -VM $destVM -disable
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Unmanaged Disk Config Created Successfully!"
    Write-Output ""   
    
    # Create Destination Virtual Machine
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Destination Virtual Machine is now being provisioned..."
    $destVM = New-AzVM -ResourceGroupName $sourceResourceGroup -Location $location -VM $destVM -LicenseType "Windows_Server" -ErrorVariable vmError -ErrorAction SilentlyContinue
    if ($vmError) 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] An error occured during the VM creation please check the destination VM is in a running state before proceeding."
        Write-Output ""
    } else 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Destination VM Created Successfully!"
        Write-Output ""
    }

    # Get Latest Destination VM Config
    $destVM = Get-AzVM -Name $sourceVM.Name -ResourceGroupName $sourceResourceGroup

    #Stop Destination Azure Virtual Machine
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Destination Virtual Machine..."
    Stop-AzVM -Name $destVM.Name -ResourceGroupName $destVM.ResourceGroupName -Force
    while ((Get-AzVM -Status -Name $destVM.Name -ResourceGroupName $destVM.ResourceGroupName).Statuses[1].DisplayStatus -ne "VM deallocated") 
    {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] VM currently shutting down sleeping for 10 Seconds."
        Start-Sleep -Seconds 10
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Destination Virtual Machine is now in a stopped state"
    Write-Output ""

    # Migrate Data Disks from Source VM to Destination VM
    if ($null -ne $sourceVM.StorageProfile.DataDisks) 
    {
        foreach ($Disk in $sourceVM.StorageProfile.DataDisks) 
        {
            $uri = $null
            $uri = Read-Host ("Please provide the VHD URI for " + $Disk.Name)
            Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding " + $Disk.Name + " to Destination VM")
            Add-AzVMDataDisk -VM $destVM -Name $Disk.Name -VhdUri $uri -Caching $Disk.Caching -Lun $Disk.Lun -CreateOption Attach 
            Update-AzVM -ResourceGroupName $destVM.ResourceGroupName -VM $destVM
            Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] " + $Disk.Name + " Added Successfully!")
            Write-Output ""
        }
    }
}

## Start Destination VM
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Powering on the Migrated VM..."
Start-AzVM -Name $destVM.Name -ResourceGroupName $destVM.ResourceGroupName
while ((Get-AzVM -Status -Name $destVM.Name -ResourceGroupName $destVM.ResourceGroupName).Statuses[1].DisplayStatus -ne "VM running") 
{
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] VM currently powering on sleeping for 10 Seconds."
    Start-Sleep -Seconds 10
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Destination VM has Powered Up Successfully!"
Write-Output ""

## Manual Cleanup Reminder
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Migration Completed successfully! Please cleanup the below resources:"
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Network Interface - $($sourceVM.NetworkProfile.NetworkInterfaces.Id.Split('/')[8])"
if ($null -ne $sourceVM.AvailabilitySetReference.Id) 
{
    Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Availability Set - " + ($sourceVM.AvailabilitySetReference.Id).Split('/')[8])
}