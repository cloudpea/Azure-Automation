Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId
)
Write-Output ""
Write-Output "Azure Unattached VHDs"
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


#Set Script Option
Write-Output ""
Write-Output "There are 3 options for using this script."
Write-Output "1. Filter by storage account, specifying the RG and SA name - quick"
Write-Output "2. Filter using a match in a SA name - moderate"
Write-Output "3. No filter. Gets all VHDs in all storage accounts in the subscription - slow"
Write-Output ""
Write-Output ""
$Option = Read-Host "Specify one of the above options [1, 2, 3]"
Write-Output ""

#Check Script Option is valid
while ($Option -ne "1" -and $Option -ne "2" -and $Option -ne "3"){
    Write-Output "Option is invalid"
    $Option = Read-Host "Please specify option 1, 2 or 3"
    Write-Output ""
}

#Set CSV Headers
Write-Output ""
"""Uri"",""AttachedToVMName"",""Lease Status"",""Lease State"",""Storage Type"",""Storage Tier"",""StorageAccount Name"",""Location"",""Resource Group"",""Size GB""" | Out-File -Encoding ASCII -FilePath ".\VHD Information.csv"


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


#Option 1 - Collect for Single Storage Account
If ($Option -eq "1") {

    #Set Storage Account Name and Resource Group Parameters
    $ResourceGroup = Read-Host "Specify the Resource Group of the Storage Account"
    $StorageAccountName = Read-Host "Specify the Name of the Storage Account"
    Write-Output ""

    $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName
    foreach ($Container in $StorageAccount | Get-AzureStorageContainer) {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Container -" $Container.Name
        foreach ($VHD in $Container | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}) {
        
            #Append VHD to CSV
            """"+$VHD.ICloudBlob.Uri.AbsoluteUri+""","""+$VHD.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName+""","""+$VHD.ICloudBlob.Properties.LeaseStatus+""","""+
            $VHD.ICloudBlob.Properties.LeaseState+""","""+$StorageAccount.Sku.Name+""","""+$StorageAccount.Sku.Tier+""","""+$StorageAccount.StorageAccountName+""","""+
            $StorageAccount.Location+""","""+$StorageAccount.ResourceGroupName+""","""+$VHD.Length / 1024 / 1024 / 1024+"""" | 
            Out-File -Encoding ASCII -FilePath ".\VHD Information.csv" -Append
        }
    }
}


#Option 2 - Collect Storage Accounts that match input string
If ($Option -eq "2") {
    
    #Set Search String Parameter
    $SearchString = Read-Host "Specify the string to search for in the Storage Account Name"

    #Parse each storage account based on input string
    foreach ($StorageAccount in Get-AzureRmStorageAccount | Where {$_.StorageAccountName -match $SearchString}) {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" $StorageAccount.StorageAccountName

        #Parse each container in Storage Account
        foreach ($Container in $StorageAccount | Get-AzureStorageContainer) {
            Write-Output "                    Processing Container -" $Container.Name

            #Parse each VHD in Container
            foreach ($VHD in $Container | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}) {
        
                #Append VHD to CSV
                """"+$VHD.ICloudBlob.Uri.AbsoluteUri+""","""+$VHD.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName+""","""+$VHD.ICloudBlob.Properties.LeaseStatus+""","""+
                $VHD.ICloudBlob.Properties.LeaseState+""","""+$StorageAccount.Sku.Name+""","""+$StorageAccount.Sku.Tier+""","""+$StorageAccount.StorageAccountName+""","""+
                $StorageAccount.Location+""","""+$StorageAccount.ResourceGroupName+""","""+$VHD.Length / 1024 / 1024 / 1024+"""" | 
                Out-File -Encoding ASCII -FilePath ".\VHD Information.csv" -Append
            }
        }
    }
}



#Option 3 - Collect data for all storage accounts.
If ($Option -eq "3") {
    foreach ($StorageAccount in Get-AzureRmStorageAccount) {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" $StorageAccount.StorageAccountName

        foreach ($Container in $StorageAccount | Get-AzureStorageContainer) {
            Write-Output "                    Processing Container -" $Container.Name
            foreach ($VHD in $Container | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}) {
        
                #Append VHD to CSV
                """"+$VHD.ICloudBlob.Uri.AbsoluteUri+""","""+$VHD.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName+""","""+$VHD.ICloudBlob.Properties.LeaseStatus+""","""+
                $VHD.ICloudBlob.Properties.LeaseState+""","""+$StorageAccount.Sku.Name+""","""+$StorageAccount.Sku.Tier+""","""+$StorageAccount.StorageAccountName+""","""+
                $StorageAccount.Location+""","""+$StorageAccount.ResourceGroupName+""","""+$VHD.Length / 1024 / 1024 / 1024+"""" | 
                Out-File -Encoding ASCII -FilePath ".\VHD Information.csv" -Append
            }
        }
    }
}