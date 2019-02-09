Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId
)
Write-Output ""
Write-Output "Azure Blob Information"
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


#Set Script Option
Write-Output ""
Write-Output "There are 3 options for using this script."
Write-Output "1. Filter by storage account, specifying the RG and SA name - quick"
Write-Output "2. Filter using a match in a SA name - moderate"
Write-Output "3. No filter. Gets all Blobs in all storage accounts in the subscription - slow"
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

#Set CSV Headers and Path
Write-Output ""
"""BlobType"",""Number of Blobs""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv"


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

    #Set Blob Type Counts
    $HotCount = 0
    $CoolCount = 0
    $ArchiveCount = 0

    #Set Storage Account Name and Resource Group Parameters
    $ResourceGroup = Read-Host "Specify the Resource Group of the Storage Account"
    $StorageAccountName = Read-Host "Specify the Name of the Storage Account"
    Write-Output ""

    #Get Specified Storage Account
    Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" + $StorageAccount.StorageAccountName)
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName
    
    #Parse each container in Storage Account
    foreach ($Container in $StorageAccount | Get-AzStorageContainer) {
        Write-Output ("Processing Container - " + $Container.Name)
        
        #Parse each Blob in Container
        foreach ($Blob in $Container | Get-AzStorageBlob) {
            
            #Get Blob Type and Increment Count
            if ($Blob.AccessTier -eq "Hot") {
                $HotCount++
            }
            if ($Blob.AccessTier -eq "Cool") {
                $CoolCount++
            }
            if ($Blob.AccessTier -eq "Archive") {
                $ArchiveCount++
            }
        }
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] All Containers Processed"
    Write-Output ""

    # Write Results to CSV
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Writing Results to CSV..."
    """"+"Hot"+""","""+$HotCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    """"+"Cool"+""","""+$CoolCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    """"+"Archive"+""","""+$ArchiveCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSV Exported Successfully!"
}


#Option 2 - Collect Storage Accounts that match input string
If ($Option -eq "2") {
    
    #Set Search String Parameter
    $SearchString = Read-Host "Specify the string to search for in the Storage Account Name"

    #Parse each storage account based on input string
    foreach ($StorageAccount in Get-AzStorageAccount | Where {$_.StorageAccountName -match $SearchString -and $_.Kind -eq "BlobStorage" -or $_.Kind -eq "StorageV2"}) {
        Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" + $StorageAccount.StorageAccountName)

        #Parse each container in Storage Account
        foreach ($Container in $StorageAccount | Get-AzStorageContainer) {
            Write-Output ("Processing Container - " + $Container.Name)

            #Parse each Blob in Container
            foreach ($Blob in $Container | Get-AzStorageBlob) {
            
                #Get Blob Type and Increment Count
                if ($Blob.AccessTier -eq "Hot") {
                    $HotCount++
                }
                if ($Blob.AccessTier -eq "Cool") {
                    $CoolCount++
                }
                if ($Blob.AccessTier -eq "Archive") {
                    $ArchiveCount++
                }
            }
        }
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] All Containers Processed"
    Write-Output ""

    # Write Results to CSV
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Writing Results to CSV..."
    """"+"Hot"+""","""+$HotCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    """"+"Cool"+""","""+$CoolCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    """"+"Archive"+""","""+$ArchiveCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSV Exported Successfully!"
}



#Option 3 - Collect data for all storage accounts.
If ($Option -eq "3") {

    #Get All Storage Account in Subscription
    foreach ($StorageAccount in Get-AzStorageAccount) {
        Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" + $StorageAccount.StorageAccountName)

        #Parse each container in Storage Account
        foreach ($Container in $StorageAccount | Get-AzStorageContainer) {
            Write-Output ("Processing Container - " + $Container.Name)

            #Parse each Blob in Container
            foreach ($Blob in $Container | Get-AzStorageBlob) {
            
                #Get Blob Type and Increment Count
                if ($Blob.AccessTier -eq "Hot") {
                    $HotCount++
                }
                if ($Blob.AccessTier -eq "Cool") {
                    $CoolCount++
                }
                if ($Blob.AccessTier -eq "Archive") {
                    $ArchiveCount++
                }
            }
        }
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] All Containers Processed"
    Write-Output ""

    # Write Results to CSV
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Writing Results to CSV..."
    """"+"Hot"+""","""+$HotCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    """"+"Cool"+""","""+$CoolCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    """"+"Archive"+""","""+$ArchiveCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSV Exported Successfully!"
}