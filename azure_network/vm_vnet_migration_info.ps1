Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Azure Region Location - westeurope, ukwest")]
  [string]$vnetName
)
Write-Output ""
Write-Output "Azure VM Virtual Network Info"
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
"""Attached Network Interfaces""" | Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv"
"""ResourceGroup"",""VMName"",""NIC Name"",""NSG"",""IPConfig"",""VMSize"",""OSType"",""Current vNet"",""Public IP"",""Private IP "",""IP Type"",""Managed Disk (Y/N)"",""# DataDisks""" | Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv" -Append

#Get Attached Network Interfaces
Write-Output ""
Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting Attached Network Interfaces in " + $vnetName)
foreach ($NIC in Get-AzNetworkInterface | Where-Object {$_.IpConfigurations.Subnet.Id -like "*$vnetName*" -and $_.VirtualMachine.Id -ne $null}) 
{
    $VM = $null
    $VM = Get-AzVM -Name ($NIC.VirtualMachine.Id).Split('/')[8] -ResourceGroupName ($NIC.VirtualMachine.Id).Split('/')[4]
    Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing VM - " + $VM.Name)

    # Check Disk Type
    if ($null -ne $VM.StorageProfile.OsDisk.ManagedDisk)
    {
        $diskType  = "Y"
    } else 
    {
        $diskType = "N"
    }

    # Count Number of Data Disks
    $diskCount = $VM.StorageProfile.DataDisks.Count

    # Get Network Security Group
    if ($null -ne $NIC.NetworkSecurityGroup)
    {
        $NSG = $NIC.NetworkSecurityGroup.Id.Split("/")[8] 
    } else
    {
        $NSG = "N/A"
    }


    foreach($IP in Get-AzNetworkInterfaceIpConfig -NetworkInterface $NIC)
    {
        # Check for Public IP
        if ($null -ne $IP.PublicIpAddress)
        {
            $PublicIP = $IP.PublicIpAddress
        } else 
        {
            $PublicIP = "N/A"
        }

        #Write Output for VM to CSV
        """"+$NIC.ResourceGroupName+""","""+$VM.Name+""","""+$NIC.Name+""","""+$NSG+""","""+$IP.Name+""","""+$VM.HardwareProfile.VmSize+""","""+$VM.StorageProfile.OsDisk.OsType+""","""+$vnetName+""","""+$PublicIP+""","""+$IP.PrivateIpAddress+""","""+$IP.PrivateIpAllocationMethod+""","""+$diskType+""","""+$diskCount+"""" | 
        Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv" -Append
    }
}

# Create CSV Headers for Unattached Interfaces
"" | Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv" -Append
"" | Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv" -Append
"""Unattached Network Interfaces""" | Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv" -Append
"""ResourceGroup"",""NIC Name"",""NSG"",""IPConfig"",""Current vNet"",""Public IP"",""Private IP "",""IP Type""" | Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv" -Append


# Get Unattached Network Interfaces
Write-Output ""
Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting Unattached Network Interfaces in " + $vnetName)
foreach ($NIC in Get-AzNetworkInterface | Where-Object {$_.IpConfigurations.Subnet.Id -like "*$vnetName*" -and $_.VirtualMachine.Id -eq $null})
{
    Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing NIC - " + $NIC.Name)
    foreach($IP in Get-AzNetworkInterfaceIpConfig -NetworkInterface $NIC)
    {
        # Check for Public IP
        if ($null -ne $IP.PublicIpAddress)
        {
            $PublicIP = $IP.PublicIpAddress
        } else 
        {
            $PublicIP = "N/A"
        }

        #Write Output for VM to CSV
        """"+$NIC.ResourceGroupName+""","""+$NIC.Name+""","""+$NSG+""","""+$IP.Name+""","""+$vnetName+""","""+$PublicIP+""","""+$IP.PrivateIpAddress+""","""+$IP.PrivateIpAllocationMethod+"""" | 
        Out-File -Encoding ASCII -FilePath ".\vm_vnet_migration_info.csv" -Append
    }
} 

Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Virtual Machine Network Information Gathered!"