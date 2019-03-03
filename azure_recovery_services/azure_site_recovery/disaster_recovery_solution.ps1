Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Source Azure Region Location - westeurope, ukwest")]
  [string]$sourceLocation,

  [Parameter(Mandatory=$True, HelpMessage="Recovery Azure Region Location - westeurope, ukwest")]
  [string]$recoveryLocation,

  [Parameter(Mandatory=$True, HelpMessage="Name of the Recovery Services Vault")]
  [string]$vaultName,

  [Parameter(Mandatory=$True, HelpMessage="Name of the Resource Group Name to Deploy Resources")]
  [securestring]$resourceGroupName,

)
Write-Output ""
Write-Output "Create ARM Recovery Services Vaults - Based on DR Tier Tag"
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
 
## Create the Resource Group
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Resource Group $resourceGroupName" -foregroundcolor "Yellow"
New-AzResourceGroup –Name $resourceGroupName –Location $recoveryLocation
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Resource group $resourceGroupName was created" -foregroundcolor "Yellow"
Write-Output ""

## Create the Recovery Services Vaults
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Recovery Services vault $vaultName..." -foregroundcolor "Yellow"
New-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroupName -Location $recoveryLocation
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Recovery Services vault created successfully!" -foregroundcolor "Yellow"
Write-Output ""

## Set Vault Context
$vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroupName
Set-AzRecoveryServicesAsrVaultContext -Vault $vault

## Create the ASR Fabrics
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating ASR Fabrics..." -foregroundcolor "Yellow"
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Name "Azure-$sourceLocation"  -Location $sourceLocation
# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Name "Azure-$recoveryLocation"  -Location $recoveryLocation
# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
    sleep 10;
    $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

$sourceFabric = Get-AzRecoveryServicesAsrFabric -Name "Azure-$sourceLocation"
$recoveryFabric = Get-AzRecoveryServicesAsrFabric -Name "Azure-$recoveryLocation"
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] ASR Fabrics Created Successfully!" -foregroundcolor "Yellow"
Write-Output ""
 
## Create Recovery Policies
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Replication Policies.." -foregroundcolor "Yellow"
$Tier1VMCount = (Get-AzVM | Where-Object {$_.Tags.DR -eq "Tier 1"}).Count
$Tier2VMCount = (Get-AzVM | Where-Object {$_.Tags.DR -eq "Tier 2"}).Count
$Tier3VMCount = (Get-AzVM | Where-Object {$_.Tags.DR -eq "Tier 3"}).Count
$Tier1PolicyCount = [math]::ceiling($Tier1VMCount / 40)
$Tier2PolicyCount = [math]::ceiling($Tier2VMCount / 40)
$Tier3PolicyCount = [math]::ceiling($Tier3VMCount / 40)

$PolicyCount = 0
while ($PolicyCount -lt $Tier1PolicyCount) {

    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Recovery Policys
    $TempASRJob = New-AzRecoveryServicesAsrPolicy -Name "ASR-T1-POLICY-$PolicyCount" -AzureToAzure `
    -ApplicationConsistentSnapshotFrequencyInHours 1`
    -RecoveryPointRetentionInHours 48
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $T1Policy = Get-AzRecoveryServicesAsrPolicy -Name "ASR-T1-POLICY-$PolicyCount"

    ## Create the Protection Containers
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -Name "ASR-T1-CONTAINER-$PolicyCount" -InputObject $sourceFabric
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -Name "ASR-T1-CONTAINER-$PolicyCount-DR" -InputObject $recoveryFabric
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $sourceContainer = Get-ASRProtectionContainer -Fabric $sourceFabric -Name "ASR-T1-CONTAINER-$PolicyCount"
    $recoveryContainer = Get-ASRProtectionContainer -Fabric $recoveryFabric -Name "ASR-T1-CONTAINER-$PolicyCount-DR"

    ## Create the Protection Container Mappings
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ASR-T1-MAPPING-$PolicyCount" -Policy $T1Policy `
    -PrimaryProtectionContainer $sourceContainer -RecoveryProtectionContainer $recoveryContainer
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ASR-T1-MAPPING-$PolicyCount" -Policy $T3Policy `
    -PrimaryProtectionContainer $sourceContainer -RecoveryProtectionContainer $recoveryContainer
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }

    #Create Cache storage account for replication logs in the primary region
    $T1StorageAccount = New-AzStorageAccount -Name ("satier1cacheasr"+$(Get-Random -Maximum 99999999)) -ResourceGroupName $resourceGroupName -Location $sourceLocation `
    -SkuName Standard_LRS -Kind Storage -Tag @{DR="Tier 1"}

}

$PolicyCount = 0
while ($PolicyCount -lt $Tier2PolicyCount) {

    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Recovery Policy
    $TempASRJob = New-AzRecoveryServicesAsrPolicy -Name "ASR-T2-POLICY-$PolicyCount" -AzureToAzure `
    -ApplicationConsistentSnapshotFrequencyInHours 4`
    -RecoveryPointRetentionInHours 24
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $T2Policy = Get-AzRecoveryServicesAsrPolicy -Name "ASR-T2-POLICY-$PolicyCount"

    ## Create the Protection Containers
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -Name "ASR-T2-CONTAINER-$PolicyCount" -InputObject $sourceFabric
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -Name "ASR-T2-CONTAINER-$PolicyCount-DR" -InputObject $recoveryFabric
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $sourceContainer = Get-ASRProtectionContainer -Fabric $sourceFabric -Name "ASR-T2-CONTAINER-$PolicyCount"
    $recoveryContainer = Get-ASRProtectionContainer -Fabric $recoveryFabric -Name "ASR-T2-CONTAINER-$PolicyCount-DR"

    ## Create the Protection Container Mappings
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ASR-T2-MAPPING-$PolicyCount" -Policy $T2Policy `
    -PrimaryProtectionContainer $sourceContainer -RecoveryProtectionContainer $recoveryContainer
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ASR-T2-MAPPING-$PolicyCount" -Policy $T2Policy `
    -PrimaryProtectionContainer $sourceContainer -RecoveryProtectionContainer $recoveryContainer
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }

    #Create Cache storage account for replication logs in the primary region
    $T2StorageAccount = New-AzStorageAccount -Name ("satier2cacheasr"+$(Get-Random -Maximum 99999999)) -ResourceGroupName $resourceGroupName -Location $sourceLocation `
    -SkuName Standard_LRS -Kind Storage -Tag @{DR="Tier 2"}
}

$PolicyCount = 0
while ($PolicyCount -lt $Tier3PolicyCount) {
    
    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Recovery Policy
    $TempASRJob = New-AzRecoveryServicesAsrPolicy -Name "ASR-T3-POLICY-$PolicyCount" -AzureToAzure `
    -ApplicationConsistentSnapshotFrequencyInHours 12`
    -RecoveryPointRetentionInHours 12
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $T3Policy = Get-AzRecoveryServicesAsrPolicy -Name "ASR-T3-POLICY-$PolicyCount"

    ## Create the Protection Containers
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -Name "ASR-T3-CONTAINER-$PolicyCount" -InputObject $sourceFabric
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -Name "ASR-T3-CONTAINER-$PolicyCount-DR" -InputObject $recoveryFabric
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    $sourceContainer = Get-ASRProtectionContainer -Fabric $sourceFabric -Name "ASR-T3-CONTAINER-$PolicyCount"
    $recoveryContainer = Get-ASRProtectionContainer -Fabric $recoveryFabric -Name "ASR-T3-CONTAINER-$PolicyCount-DR"

    ## Create the Protection Container Mappings
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ASR-T3-MAPPING-$PolicyCount" -Policy $T3Policy `
    -PrimaryProtectionContainer $sourceContainer -RecoveryProtectionContainer $recoveryContainer
    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }
    #Track Job status to check for completion
    $TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "ASR-T3-MAPPING-$PolicyCount" -Policy $T3Policy `
    -PrimaryProtectionContainer $sourceContainer -RecoveryProtectionContainer $recoveryContainer
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }

    #Create Cache storage account for replication logs in the primary region
    $T3StorageAccount = New-AzStorageAccount -Name ("satier3cacheasr"+$(Get-Random -Maximum 99999999)) -ResourceGroupName $resourceGroupName -Location $sourceLocation `
    -SkuName Standard_LRS -Kind Storage -Tag @{DR="Tier 3"}
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Replication Policies Created Successfully!." -foregroundcolor "Yellow"
Write-Output ""

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Configuring Replication for Azure Virtual Machines..." -foregroundcolor "Yellow"
## Zero the itemcount hashtable (and create it if needed)
$itemcount = @{}
## Add VMs to relevant Vault and Protection Container
foreach ($VM in Get-AzVM | Where-Object {$_.Tags.DR -ne $null}) {
    Write-Output ("Configuring VM Replication - "+$VM.Name)
    
    $crit_string = $VM.Tags.DR

    ## Check it matches the regex for format
    if ($crit_string -match "Tier [1-3]") {
        #tier is always in format "Tier X" so
        [int]$tier = $crit_string.Split(" ")[1]

        ## If the key hasnt been created then create it
        if (-not $itemcount.$tier) {
            $itemcount.$tier = 0
        }
        $vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroupName
        Set-AzRecoveryServicesVaultContext -Vault $vault

        ## Get ASR Fabric
        $sourceFabric = Get-AzRecoveryServicesAsrFabric -Name "Azure-$sourceLocation"
        $recoveryFabric = Get-AzRecoveryServicesAsrFabric -Name "Azure-$recoveryLocation"     

        ## Get Source VM Virtual Network Information
        $subnetid = (Get-AzNetworkInterface -Name ($VM.NetworkProfile.NetworkInterfaces[0].id).Split('/')[8] -ResourceGroupName $VM.ResourceGroupName).IpConfigurations.Subnet.Id
        $primarynetwork = Get-AzVirtualNetwork -Name $subnetid.Split('/')[8]  -ResourceGroupName $subnetid.Split('/')[4] 

        ## Check if Recovery Network Already Exists in ASR
        $ASRNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $sourceFabric -Name $primarynetwork.Name -ErrorVariable NetworkError -ErrorAction SilentlyContinue
        if($NetworkError){
            # Check if Recovery Network Resource Group Exists
            $recoverynetworkresourcegroup = Get-AzResourceGroup -Name ($primarynetwork.ResourceGroupName+"-ASR") -Location $recoveryLocation -ErrorVariable NetworkGroupError -ErrorAction SilentlyContinue
            if($NetworkGroupError) {
                # Create Recovery Network Resource Group
                $recoverynetworkresourcegroup = New-AzResourceGroup -Name ($primarynetwork.ResourceGroupName+"-ASR") -Location $recoveryLocation
                $NetworkGroupError = $null
            }        
    
            # Create Recovery Network
            $recoverynetwork = New-AzVirtualNetwork -Name ($subnetid.Split('/')[8]+"-ASR")  -Location $recoveryLocation `
            -ResourceGroupName $recoverynetworkresourcegroup.ResourceGroupName -AddressPrefix  $primarynetwork.AddressSpace.AddressPrefixes[0] 
            
            # Create Recovery Network Mappings
            $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -Name $primarynetwork.Name -AzureToAzure `
            -PrimaryFabric $sourceFabric -RecoveryFabric $recoveryFabric `
            -PrimaryAzureNetworkId $primarynetwork.Id -RecoveryAzureNetworkId $recoverynetwork.Id
            #Track Job status to check for completion
            while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                sleep 10;
                $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
            }
            $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -Name $recoverynetwork.Name -AzureToAzure `
            -PrimaryFabric $recoveryFabric -RecoveryFabric $sourceFabric `
            -PrimaryAzureNetworkId $recoverynetwork.Id -RecoveryAzureNetworkId $primarynetwork.Id
            #Track Job status to check for completion
            while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
                sleep 10;
                $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
            }
            $NetworkError = $null
        }

        # Create Empty Array of Disk Configs
        $disks = @()
        $diskcount = 0

        # Check if Recovery VM Resource Group Exists
        $recoveryvmresourcegroup = Get-AzResourceGroup -Name ($VM.ResourceGroupName+"-ASR") -Location $recoveryLocation -ErrorVariable VMGroupError -ErrorAction SilentlyContinue
        if($VMGroupError) {
            # Create Recovery VM Resource Group
            $recoveryvmresourcegroup = New-AzResourceGroup -Name ($VM.ResourceGroupName+"-ASR") -Location $recoveryLocation
            $VMGroupError = $null
        }   

        ## Create OS Disk Replication Config
        $osdisk = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk `
        -LogStorageAccountId (Get-Variable -Name ("T"+$tier+"StorageAccount") -ValueOnly).Id`
        -RecoveryResourceGroupId $recoveryvmresourcegroup.ResourceId `
        -RecoveryReplicaDiskAccountType $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType `
        -RecoveryTargetDiskAccountType $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType `
        -DiskId $VM.StorageProfile.OsDisk.ManagedDisk.Id
        $disks += $osdisk

        ## Create Data Disk Replication Configs
        foreach ($disk in $VM.StorageProfile.DataDisks){
            $diskcount++
            New-Variable -Name datadisk$diskcount -Value (New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk `
            -LogStorageAccountId (Get-Variable -Name ("T"+$tier+"StorageAccount") -ValueOnly).Id `
            -RecoveryResourceGroupId $recoveryvmresourcegroup.ResourceId `
            -RecoveryReplicaDiskAccountType $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType `
            -RecoveryTargetDiskAccountType $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType `
            -DiskId $VM.StorageProfile.OsDisk.ManagedDisk.Id)
            $disks += (, (Get-Variable -Name datadisk$diskcount -ValueOnly))
        }

        # Create Container and Mapping Names
        $base_container_name = "ASR-T#-CONTAINER-"
        $base_mapping_name = "ASR-T#-MAPPING-"
        $container_name = $base_container_name.Replace("#", $tier)
        $mapping_name = $base_mapping_name.Replace("#", $tier)
        $full_container_name = $container_name + ([math]::floor($itemcount.$tier++ /  40) + 1).ToString()
        $full_mapping_name = $mapping_name + ([math]::floor($itemcount.$tier++ /  40) + 1).ToString()
        
        # Create Recovery Item
        $container = Get-AzRecoveryServicesAsrProtectionContainer -Name $full_container_name -Fabric $sourceFabric
        $mapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $full_mapping_name -ProtectionContainer $container
        $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -Name $VM.Name -RecoveryVmName ($VM.Name+"-ASR") -AzureToAzure `
        -AzureVmId $VM.VmId -RecoveryResourceGroupId $recoveryvmresourcegroup.ResourceId `
        -ProtectionContainerMapping $mapping -AzureToAzureDiskReplicationConfiguration $disks
        #Track Job status to check for completion
        while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
            sleep 10;
            $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
        }
    }
    else {
        if ($crit_string -match "Tier $tier") {}
        else {
            ## Doesnt match, throw an error
            Write-Output $VM.Name " has a incorrectly formatted DR Tier Tag -> " $VM.Tags.DR
        }
    }
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Azure Virtual Machine Replication Configured Successfully!" -foregroundcolor "Yellow"
