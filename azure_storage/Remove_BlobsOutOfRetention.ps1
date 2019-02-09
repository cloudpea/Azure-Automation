function Remove-BlobsOutOfRetention
{
  Param(
    [parameter(Mandatory, HelpMessage="Specify the subscription ID.")]
    [string]$SubscriptionId,
    [parameter(Mandatory, HelpMessage="Specify the storage account name.")]
    [string]$StorageAccountName,
    [parameter(Mandatory, HelpMessage="Specify the container name.")]
    [string]$ContainerName,
    [parameter(Mandatory, HelpMessage="Specify the number of backups must be retained.")]
    [int]$RetentionDays,
    [parameter(HelpMessage="Specify a BLOB pattern to match against.")]
    [string]$BlobPattern = "*"
  )

  Try {
    Import-Module Az
  } Catch {
    Write-Error "ERROR: Could not import module: Az"
  }

  # Configure the connection
  Try {
    Connect-AzAccount -SubscriptionId $SubscriptionId
  } Catch {
    Write-Error "ERROR: Problem accessing subscription. Please check the subscription ID and verify the correct account is being used to access Azure."
  }

  # Initialise variables
  $Retention = (Get-Date).AddDays(-$RetentionDays)
  $StorageAccountDetail = (Get-AzResource | Where-Object { $_.Kind -like "*blobstorage*" -and $_.Name -like "*$StorageAccountName*" })

  If ($null -ne $StorageAccountDetail) {
    $StorageAccountDetail = $StorageAccountDetail.ResourceId.Split("/")
    # Access and perform operations on the storage account.
    $StorageAccount = Get-AzStorageAccount -StorageAccountName $StorageAccountDetail[8] -ResourceGroupName $StorageAccountDetail[4]
    $Container = $StorageAccount | Get-AzStorageContainer -Name $ContainerName
    ForEach ($Blob In $Container | Get-AzStorageBlob -Blob "*$BlobPattern*" | Where-Object { $_.LastModified -lt $Retention }) {
      $StorageAccount | Remove-AzStorageBlob -Blob $Blob.Name -Container $Container.Name -Verbose
    }
  } Else {
    Write-Error "ERROR: Problem accessing blobs. Please check that the Storage Account and Container exist and ensure the parameters set are correct."
  }
  Return $Container
}