Param (
  [Parameter(Mandatory=$True)]
  [string]$subcriptionId
)
Write-Output ""
Write-Output "Azure Blob Information"
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

#Set CSV Headers
""""+"StorageAccount"+""","""+"Table Storage"+""","""+"Queue Storage"+""","""+"File Storage"+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv"

#Set Blob Type Counts
$HotCount = 0
$CoolCount = 0
$ArchiveCount = 0

#Get All Storage Account in Subscription
foreach ($StorageAccount in Get-AzStorageAccount) {
    Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" + $StorageAccount.StorageAccountName)

    $TableEndpoint = "Disabled"
    Write-Output ("Debugging - TableEndpoint Default: " + $TableEndpoint)
    $QueueEndpoint = "Disabled"
    Write-Output ("Debugging - QueueEndpoint Default: " + $QueueEndpoint)
    $FileEndpoint = "Disabled"
    Write-Output ("Debugging - FileEndpoint Default: " + $FileEndpoint)

    #Check for File, Queue & Table Storage
    if ($StorageAccount.Kind -eq "StorageV2" -or $StorageAccount.Kind -eq "Storage") {

        if ($null -ne $StorageAccount.Context.TableEndPoint) {
            $TableEndpoint = "Enabled"
            Write-Output ("Debugging - TableEndpoint Updated: " + $TableEndpoint)
        }
        if ($null -ne $StorageAccount.Context.QueueEndPoint) {
            $QueueEndpoint = "Enabled"
            Write-Output ("Debugging - TableEndpoint Updated: " + $TableEndpoint)
        }
        if ($null -ne $StorageAccount.Context.FileEndPoint) {
            $TableEndpoint = "Enabled"
            Write-Output ("Debugging - TableEndpoint Updated: " + $TableEndpoint)
        }
        """"+$StorageAccount.StorageAccountName+""","""+$TableEndpoint+""","""+$QueueEndpoint+""","""+$FileEndpoint+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append


    }

    #Check for Configured Access Tier
    if ($StorageAccount.Kind -eq "StorageV2" -or $StorageAccount.Kind -eq "BlobStorage") {
        #Get Storage Type and Increment Count
        if ($StorageAccount.AccessTier -eq "Hot") {
            $HotCount++
        }
        if ($StorageAccount.AccessTier -eq "Cool") {
            $CoolCount++
        }
        if ($StorageAccount.AccessTier -eq "Archive") {
            $ArchiveCount++
        }
    }
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] All Containers Processed"
Write-Output ""
# Write Results to CSV
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Writing Results to CSV..."
Write-Output "" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
"""StorageAccount Type"",""Number of Storage Accounts""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
""""+"Hot"+""","""+$HotCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
""""+"Cool"+""","""+$CoolCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
""""+"Archive"+""","""+$ArchiveCount+"""" | Out-File -Encoding ASCII -FilePath ".\Blob Information.csv" -Append
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSV Exported Successfully!"