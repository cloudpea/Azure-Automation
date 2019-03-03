Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="Azure Region Location - westeurope, ukwest")]
  [string]$location,

  [Parameter(Mandatory=$True, HelpMessage="A Prefix for the Recovery Services Vault")]
  [string]$vaultPrefix,

  [Parameter(Mandatory=$True, HelpMessage="Resource Group Name of the Recovery Services Vault")]
  [securestring]$resourceGroupName,

)
Write-Output ""
Write-Output "Create ARM Recovery Services Vaults - Based on Backup Tier Tag"
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
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Recovery Services vault " ($vaultPrefix + "-GRS") " is being created" -foregroundcolor "Yellow"
New-AzRecoveryServicesVault -Name ($vaultPrefix + "-GRS") -ResourceGroupName $resourceGroupName -Location $location
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Recovery Services vault " ($vaultPrefix + "-LRS") " is being created" -foregroundcolor "Yellow"
New-AzRecoveryServicesVault -Name ($vaultPrefix + "-LRS") -ResourceGroupName $resourceGroupName -Location $location

 
## Set Correct Storage Redundacy on each Vault
$GRSVault = Get-AzRecoveryServicesVault –Name ($vaultPrefix + "-GRS")
$LRSVault = Get-AzRecoveryServicesVault –Name ($vaultPrefix + "-LRS")
Set-AzRecoveryServicesBackupProperties -Vault $GRSVault -BackupStorageRedundancy GeoRedundant
Set-AzRecoveryServicesBackupProperties -Vault $LRSVault -BackupStorageRedundancy LocallyRedundant
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Recovery Services vaults created successfully!" -foregroundcolor "Yellow"
Write-Output ""


Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating GRS Backup Policies..." -foregroundcolor "Yellow"
## Create GRS Backup Policies
$Tier1VMCount = (Get-AzVM | Where-Object {$_.Tags.Backup -eq "Tier 1"}).Count
$Tier2VMCount = (Get-AzVM | Where-Object {$_.Tags.Backup -eq "Tier 2"}).Count
$Tier1PolicyCount = [math]::ceiling($Tier1VMCount / 40)
$Tier2PolicyCount = [math]::ceiling($Tier2VMCount / 40)


$PolicyCount = 0
while ($PolicyCount -lt $Tier1PolicyCount) {

    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name ($vaultPrefix + "-GRS") -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Schedule Policy
    $SchPolT1 = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
    $SchPolT1.ScheduleRunTimes.clear()
    $SchPolT1.ScheduleRunDays.clear()
    $Dt = (Get-Date -Hour 23 -Minute 0 -Second 0 -Millisecond 0)
    $SchPolT1.ScheduleRunTimes.Add($Dt.ToUniversalTime())
    $SchPolT1.ScheduleRunFrequency = "Daily"

    ## Create the Retention Policy
    $RetPolT1 = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
    $RetPolT1.MonthlySchedule.DurationCountInMonths = 12
    $RetPolT1.WeeklySchedule.DurationCountInWeeks = 12
    $RetPolT1.DailySchedule.DurationCountInDays = 30

    ## Create the Backup Protection Policy
    New-AzRecoveryServicesBackupProtectionPolicy -Name "BP-T1-30D-12W-12M -GRS-$PolicyCount" -WorkloadType AzureVM -RetentionPolicy $RetPolT1 -SchedulePolicy $SchPolT1 $PolicyCount.ToString()
}



$PolicyCount = 0
while ($PolicyCount -lt $Tier2PolicyCount) {

    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name ($vaultPrefix + "-GRS") -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Schedule Policy
    $SchPolT2 = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
    $SchPolT2.ScheduleRunTimes.clear()
    $SchPolT2.ScheduleRunDays.clear()
    $Dt = (Get-Date -Hour 01 -Minute 0 -Second 0 -Millisecond 0)
    $SchPolT2.ScheduleRunTimes.Add($Dt.ToUniversalTime())
    $SchPolT2.ScheduleRunFrequency = "Daily"

    ## Create the Retention Policy
    $RetPolT2 = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
    $RetPolT1.WeeklySchedule.DurationCountInWeeks = 12
    $RetPolT2.DailySchedule.DurationCountInDays = 30

    ## Create the Backup Protection Policy
    New-AzRecoveryServicesBackupProtectionPolicy -Name "BP-T2-GRS-$PolicyCount" -WorkloadType AzureVM -RetentionPolicy $RetPolT2 -SchedulePolicy $SchPolT2 $PolicyCount.ToString()
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] GRS Backup Policies Created Successfully!" -foregroundcolor "Yellow"
Write-Output ""

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating LRS Backup Policies..." -foregroundcolor "Yellow"
## Create LRS Backup Policies
$Tier3VMCount = (Get-AzVM | Where-Object {$_.Tags.Backup -eq "Tier 3"}).Count
$Tier4VMCount = (Get-AzVM | Where-Object {$_.Tags.Backup -eq "Tier 4"}).Count
$Tier3PolicyCount = [math]::ceiling($Tier3VMCount / 40)
$Tier4PolicyCount = [math]::ceiling($Tier4VMCount / 40)

$PolicyCount = 0
while ($PolicyCount -lt $Tier3PolicyCount) {
    
    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name ($vaultPrefix + "-LRS") -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Schedule Policy
    $SchPolT3 = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
    $SchPolT3.ScheduleRunTimes.clear()
    $SchPolT3.ScheduleRunDays.clear()
    $Dt = (Get-Date -Hour 03 -Minute 0 -Second 0 -Millisecond 0)
    $SchPolT3.ScheduleRunTimes.Add($Dt.ToUniversalTime())
    $SchPolT3.ScheduleRunFrequency = "Daily"

    ## Create the Retention Policy
    $RetPolT3 = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
    $RetPolT3.WeeklySchedule.DurationCountInWeeks = 4
    $RetPolT3.DailySchedule.DurationCountInDays = 7

    ## Create the Backup Protection Policy
    New-AzRecoveryServicesBackupProtectionPolicy -Name "BP-T3-LRS-$PolicyCount" -WorkloadType AzureVM -RetentionPolicy $RetPolT3 -SchedulePolicy $SchPolT3 $PolicyCount.ToString()
}

$PolicyCount = 0
while ($PolicyCount -lt $Tier4PolicyCount) {
    
    ## Set Vault Context
    $vault = Get-AzRecoveryServicesVault -Name ($vaultPrefix + "-LRS") -ResourceGroupName $resourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $vault
    $PolicyCount ++

    ## Create the Schedule Policy
    $SchPolT4 = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
    $SchPolT4.ScheduleRunTimes.clear()
    $SchPolT4.ScheduleRunDays.clear()
    $Dt = (Get-Date -Hour 03 -Minute 0 -Second 0 -Millisecond 0)
    $SchPolT4.ScheduleRunTimes.Add($Dt.ToUniversalTime())
    $SchPolT4.ScheduleRunFrequency = "Daily"

    ## Create the Retention Policy
    $RetPolT4 = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
    $RetPolT4.DailySchedule.DurationCountInDays = 7

    ## Create the Backup Protection Policy
    New-AzRecoveryServicesBackupProtectionPolicy -Name "BP-T4-LRS-$PolicyCount" -WorkloadType AzureVM -RetentionPolicy $RetPolT4 -SchedulePolicy $SchPolT4 $PolicyCount.ToString()
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] LRS Backup Policies Created Successfully!" -foregroundcolor "Yellow"
Write-Output ""


Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Configuring Azure Virtual Machine Backups Based on Backup Tier Tag..." -foregroundcolor "Yellow"
## Zero the itemcount hashtable (and create it if needed)
$itemcount = @{}
$Storageredundancy = @{ 1="GRS"; 2="GRS"; 3="LRS"; 4="LRS"}
## Add VMs to relevant Vault and Backup Policy
foreach ($VM in Get-AzVM | Where-Object {$_.Tags.Backup -ne $null}) {
    Write-Output ("Configuring VM Backup - "+$VM.Name)
    
    $crit_string = $VM.Tags.Backup

    ## Check it matches the regex for format
    if ($crit_string -match "Tier [1-4]") {
        #tier is always in format "Tier X" so
        [int]$tier = $crit_string.Split(" ")[1]

        ## If the key hasnt been created then create it
        if (-not $itemcount.$tier) {
            $itemcount.$tier = 0
        }
        $vault = Get-AzRecoveryServicesVault -Name ($vaultPrefix + "-" + $Storageredundancy.$tier) -ResourceGroupName $resourceGroupName
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
        if ($crit_string -match "Tier $tier") {}
        else {
            ## Doesnt match, throw an error
            Write-Output $VM.Name " has a incorrectly formatted Backup Tier Tag -> " $VM.Tags.Backup
        }
    }
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Azure Virtual Machine Backups Configured Successfully!" -foregroundcolor "Yellow"
