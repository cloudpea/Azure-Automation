Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Azure Region Location - westeurope, ukwest")]
  [string]$location,

  [Parameter(Mandatory=$True, HelpMessage="Name of the Recovery Services Vault")]
  [string]$vaultName,

  [Parameter(Mandatory=$True, HelpMessage="Resource Group Name of the Recovery Services Vault")]
  [securestring]$resourceGroupName,

)
Write-Output ""
Write-Output "Create ARM Recovery Services Vaults - Based on Criticality Tag"
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
New-AzResourceGroup –Name $resourceGroupName –Location $location
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Resource group $resourceGroupName was created" -foregroundcolor "Yellow"

 
## Create the Recovery Services Vaults
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Recovery Services vault " ($vaultName + "-GRS") " is being created" -foregroundcolor "Yellow"
New-AzRecoveryServicesVault -Name ($vaultName + "-GRS") -ResourceGroupName $resourceGroupName -Location $location
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Recovery Services vault " ($vaultName + "-LRS") " is being created" -foregroundcolor "Yellow"
New-AzRecoveryServicesVault -Name ($vaultName + "-LRS") -ResourceGroupName $resourceGroupName -Location $location

 
## Set Correct Storage Redundacy on each Vault
$GRSVault = Get-AzRecoveryServicesVault –Name ($vaultName + "-GRS")
$LRSVault = Get-AzRecoveryServicesVault –Name ($vaultName + "-LRS")
Set-AzRecoveryServicesBackupProperties -Vault $GRSVault -BackupStorageRedundancy GeoRedundant
Set-AzRecoveryServicesBackupProperties -Vault $LRSVault -BackupStorageRedundancy LocallyRedundant
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Recovery Services vaults created successfully." -foregroundcolor "Yellow"


## Create GRS Backup Policies
$Tier1VMCount = (Get-AzVM | Where-Object {$_.Tags.Criticality -eq "Tier 1"}).Count
$Tier2VMCount = (Get-AzVM | Where-Object {$_.Tags.Criticality -eq "Tier 2"}).Count
$Tier1PolicyCount = [math]::ceiling($Tier1VMCount / 40)
$Tier2PolicyCount = [math]::ceiling($Tier2VMCount / 40)


$PolicyCount = 0
while ($PolicyCount -lt $Tier1PolicyCount) {

    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name ($vaultName + "-GRS") -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Schedule Policy
    $SchPolT1 = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
    $SchPolT1.ScheduleRunTimes.clear()
    $SchPolT1.ScheduleRunDays.clear()
    $Dt = (Get-Date -Hour 21 -Minute 0 -Second 0 -Millisecond 0)
    $SchPolT1.ScheduleRunTimes.Add($Dt.ToUniversalTime())
    $SchPolT1.ScheduleRunFrequency = "Daily"

    ## Create the Retention Policy
    $RetPolT1 = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
    $RetPolT1.DailySchedule.DurationCountInDays = 180

    ## Create the Backup Protection Policy
    New-AzRecoveryServicesBackupProtectionPolicy -Name "BP-T1-GRS-$PolicyCount" -WorkloadType AzureVM -RetentionPolicy $RetPolT1 -SchedulePolicy $SchPolT1 $PolicyCount.ToString()
}



$PolicyCount = 0
while ($PolicyCount -lt $Tier2PolicyCount) {

    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name ($vaultName + "-GRS") -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Schedule Policy
    $SchPolT2 = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
    $SchPolT2.ScheduleRunTimes.clear()
    $SchPolT2.ScheduleRunDays.clear()
    $Dt = (Get-Date -Hour 21 -Minute 0 -Second 0 -Millisecond 0)
    $SchPolT2.ScheduleRunTimes.Add($Dt.ToUniversalTime())
    $SchPolT2.ScheduleRunFrequency = "Daily"

    ## Create the Retention Policy
    $RetPolT2 = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
    $RetPolT2.DailySchedule.DurationCountInDays = 180

    ## Create the Backup Protection Policy
    New-AzRecoveryServicesBackupProtectionPolicy -Name "BP-T2-GRS-$PolicyCount" -WorkloadType AzureVM -RetentionPolicy $RetPolT2 -SchedulePolicy $SchPolT2 $PolicyCount.ToString()
}


## Create LRS Backup Policies
$Tier3VMCount = (Get-AzVM | Where-Object {$_.Tags.Criticality -eq "Tier 3"}).Count
$Tier3PolicyCount = [math]::ceiling($Tier3VMCount / 40)

$PolicyCount = 0
while ($PolicyCount -lt $Tier3PolicyCount) {
    
    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name ($vaultName + "-LRS") -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Schedule Policy
    $SchPolT3 = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
    $SchPolT3.ScheduleRunTimes.clear()
    $SchPolT3.ScheduleRunDays.clear()
    $Dt = (Get-Date -Hour 21 -Minute 0 -Second 0 -Millisecond 0)
    $SchPolT3.ScheduleRunTimes.Add($Dt.ToUniversalTime())
    $SchPolT3.ScheduleRunFrequency = "Daily"

    ## Create the Retention Policy
    $RetPolT3 = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
    $RetPolT3.WeeklySchedule.DurationCountInWeeks = 12
    $RetPolT3.DailySchedule.DurationCountInDays = 7

    ## Create the Backup Protection Policy
    New-AzRecoveryServicesBackupProtectionPolicy -Name "BP-T3-LRS-$PolicyCount" -WorkloadType AzureVM -RetentionPolicy $RetPolT3 -SchedulePolicy $SchPolT3 $PolicyCount.ToString()
}

## Zero the itemcount hashtable (and create it if needed)
$itemcount = @{}
$Storageredundancy = @{ 1="GRS"; 2="GRS"; 3="LRS"}
## Add VMs to relevant Vault and Backup Policy
foreach ($VM in Get-AzVM | Where-Object {$_.Tags.Criticality -ne $null}) {
    
    $crit_string = $VM.Tags.Criticality

    ## Check it matches the regex for format
    if ($crit_string -match "Tier [1-3]") {
        #tier is always in format "Tier X" so
        [int]$tier = $crit_string.Split(" ")[1]

        ## If the key hasnt been created then create it
        if (-not $itemcount.$tier) {
            $itemcount.$tier = 0
        }
        $vault = Get-AzRecoveryServicesVault -Name ($vaultName + "-" + $Storageredundancy.$tier) -ResourceGroupName $resourceGroupName
        Set-AzRecoveryServicesVaultContext -Vault $vault

        ## We replace the # and £ with the tier number
        $base_policy_name = "BP-T#-£-"
        $policy_name = $base_policy_name.Replace("#", $tier)
        $policy_name = $policy_name.Replace("£", $Storageredundancy.$tier)
        #build the full name out, because its less clunky
        $full_policy_name = $policy_name + ([math]::floor($itemcount.$tier++ /  40) + 1).ToString()
        #and implement
        $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $full_policy_name
        Enable-AzRecoveryServicesBackupProtection -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Policy $policy
    }
    else {
        if ($crit_string -match "Tier 4") {}
        else {
            ## Doesnt match, throw an error
            Write-Output $VM.Name " has a incorrectly formatted Criticality Tag -> " $VM.Tags.Criticality
        }
    }
}