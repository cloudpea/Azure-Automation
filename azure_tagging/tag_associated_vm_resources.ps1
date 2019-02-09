Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId
)
Write-Output ""
Write-Output "Tag Associated Azure VM Resources"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""
Write-Output ""
Write-Output "This script will tag the below associated resource types for each VM"
Write-Output "- Managed Disks"
Write-Output "- Network Interfaces"
Write-Output "- Public IP Addresses"
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


foreach ($VM in Get-AzVM | Where-Object {$_.Tags -ne $null}) {
    
    #Get Current VM Tags
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting Tags for -" $VM.Name
    $Tags = $VM.Tags
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathered Tags Successfully"
    Write-Output ""


    #Get Associated Network Interfaces and Tag
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Network Interfaces for -" $VM.Name
    $NetworkInterfaceIDs = $VM.NetworkProfile.NetworkInterfaces.Id

    foreach ($Int in $NetworkInterfaceIDs) {

        #Get Interface Name
        $IntName = $Int.Split("/")[8]

        Write-Output "Tagging Interface" $IntName
        Set-AzResource -ResourceId $Int -Tag $Tags -Force
    }

    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Network Interfaces Tagged Successfully"
    Write-Output ""


    #Get Associated Managed Disks and Tag
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Managed Disks for -" $VM.Name

    if ($VM.StorageProfile.OsDisk.ManagedDisk -ne $null) {
        $OSDisk = $VM.StorageProfile.OsDisk.Name
        $DataDisks = $VM.StorageProfile.DataDisks.Name
        $Disks = $OSDisk,$DataDisks

        foreach ($Disk in $Disks) {
            Write-Output "Tagging Managed Disk" $Disk
            $Config = New-AzDiskUpdateConfig -Tag $Tags
            $Disk = Get-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $Disk 
            Update-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $Disk.Name -DiskUpdate $Config
        }
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Managed Disks Tagged Successfully"
        Write-Output ""
    }

    else {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name "is using Unmanaged Disks"
    Write-Output ""
    }


    #Get Associated Public IP Addresses and Tag
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Public IPs for -" $VM.Name
    foreach ($Int in $NetworkInterfaceIDs) {
        
        #Get All IP Configuration for Interface
        $Int = Get-AzResource -ResourceId $Int
        $IPConfigurations = $Int.Properties.ipConfigurations

        #Check IP Configurations for Public IPs

        If ($IPConfigurations.properties.publicIPAddress -eq $null) {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] No Public IP Addresses to Tag"
        }

        #If Public IPs exist then Tag
        else {
            foreach ($IP in $IPConfigurations | Where-Object {$_.properties.publicIPAddress -ne $null}) {
                
                #Get Public IP Name
                $PIPName = $IP.properties.publicIPAddress.id.Split("/")[8]

                Write-Output "Tagging Public IP" $PIPName
                Set-AzResource -ResourceId $IP.properties.publicIPAddress.id -Tag $Tags -Force
            }
        }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Public IPs Tagged Successfully"
    Write-Output ""
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name "Tagged Successfully!"
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Completed Successfully for all Virtual Machines"
