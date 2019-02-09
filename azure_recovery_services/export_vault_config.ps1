Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="VM Tag to Include in CSV")]
  [string]$tagSearch1,

  [Parameter(Mandatory=$True, HelpMessage="VM Tag to Include in CSV")]
  [string]$tagSearch2,
)
Write-Output ""
Write-Output "Export Azure Backup Vault Configuration"
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

#Set CSV Headers for Policies in Backup Information CSV
"""Vault Name"",""Redundancy"",""Location"",""Policy Name"",""WorkLoad Type"",""Run Frequency"",""Run Time"",""Daily Retention"",""Weekly Retention"",""Monthly Retention"",""Yearly Retention""" | 
Out-File -Encoding ASCII -FilePath ".\Backup Vault Information.csv"


#Gather Backup Policies
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering Backup Vault Policies"
foreach ($Vault in Get-AzRecoveryServicesVault) {

    #Set each Vault Context
    Set-AzRecoveryServicesVaultContext -Vault $Vault
    $Redundancy = Az.RecoveryServices\Get-AzRecoveryServicesBackupProperty -Vault $Vault | Select -ExpandProperty BackupStorageRedundancy
    Write-Output "Processing Policies for Vault -"$Vault.Name
    #Get each Policy in the Vault
    foreach ($Policy in Get-AzRecoveryServicesBackupProtectionPolicy) {

        #Write Retention Variables
        $DailyRetention = $Policy.RetentionPolicy.DailySchedule.DurationCountInDays
        $WeeklyRetention = $Policy.RetentionPolicy.WeeklySchedule.DurationCountInWeeks
        $MonthlyRetention = $Policy.RetentionPolicy.MonthlySchedule.DurationCountInMonths
        $YearlyRetention = $Policy.RetentionPolicy.YearlySchedule.DurationCountInYears

        If ($WeeklyRetention -eq $null) {
            $WeeklyRetention = "0"
        }
        If ($MonthlyRetention -eq $null) {
            $MonthlyRetention = "0"
        }
        If ($YearlyRetention -eq $null) {
            $YearlyRetention = "0"
        }

        #Append each Policy to the CSV
        """"+$Vault.Name+""","""+$Redundancy+""","""+$Vault.Location+""","""+$Policy.Name+""","""+$Policy.WorkloadType+""","""+$Policy.SchedulePolicy.ScheduleRunFrequency+""","""+$Policy.SchedulePolicy.ScheduleRunTimes+
        ""","""+$DailyRetention+""","""+$WeeklyRetention+""","""+$MonthlyRetention+""","""+$YearlyRetention+"""" |
        Out-File -Encoding ASCII -FilePath ".\Backup Vault Information.csv" -Append
    }
}


#Set CSV Headers for Backup Items in Backup Information CSV
"" 
"" 
"" |
Out-File -Encoding ASCII -FilePath ".\Backup Vault Information.csv" -Append

"""Vault Name"",""Redundancy"",""Location"",""ResourceGroup Name"",""VM Name"",""VM Disk Size"",""$tagSearch1 Tag"",""$tagSearch2 Tag"",""Protection Policy"",""Protection Status""" | 
Out-File -Encoding ASCII -FilePath ".\Backup Vault Information.csv" -Append

#Set CSV Headers in Zombie Backup Items CSV
"""Vault Name"",""Redundancy"",""Location"",""Backup Item Name"",""Policy"",""Protection Status""" |
Out-File -Encoding ASCII -FilePath ".\Zombie Backup Items.csv"


#Gather Backup Items
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering Backup Vault Items"
foreach ($Vault in Get-AzRecoveryServicesVault) {

    #Set each Vault Context
    Set-AzRecoveryServicesVaultContext -Vault $Vault
    $Redundancy = Az.RecoveryServices\Get-AzRecoveryServicesBackupProperty -Vault $Vault | Select -ExpandProperty BackupStorageRedundancy

    Write-Output ""
    Write-Output "Processing Backup Items for Vault -"$Vault.Name  
    
    #Get each Container in the Vault 
    foreach ($Container in Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM") {

        #Get each Backup Item in the Container
        foreach ($Item in Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType AzureVM) {

        #Set VM and ResourceGroup Variables
        $ItemName = $Item.Name -split ";"
        $VMName = $ItemName[3]
        $ResourceGroupName = $ItemName[2]

        Write-Output "Processing Backup Item" $VMName

        
        #Check VM Exists
        $VM = Get-AzVm -ResourceGroupName $ResourceGroupName -VMName $VMName -ErrorVariable BackupError -ErrorAction SilentlyContinue

        #Get Sum of VM Disk Sizes
        $OsDiskSize = $VM.StorageProfile.OsDisk.DiskSizeGB
        $DataDiskSize = $VM.StorageProfile.DataDisks.DiskSizeGB
        $TotalSize = 0
        foreach ($Disk in $DataDiskSize) 
        { 
            $TotalSize =  $TotalSize + $Disk
        }
        $TotalSize = $TotalSize + $OsDiskSize

        if ($TotalSize -eq 0){
            $TotalSize = "N/A"
        }

        #If VM does not exist write Backup Item to Zombie CSV
        If ($BackupError) {
            Write-Output "$VMName is a Zombie Backup Item"
            """"+$Vault.Name+""","""+$Redundancy+""","""+$Vault.Location+""","""+$VMName+""","""+$Item.ProtectionPolicyName+""","""+$Item.ProtectionStatus+"""" |
            Out-File -Encoding ASCII -FilePath ".\Zombie Backup Items.csv" -Append

            $BackupError = $null

        }

        #Get Custom VM Tags Value
        $Tag1 = $VM.Tags.$tagSearch1
        $Tag2 = $VM.Tags.$tagSearch2

        #Append each Backup Item to the Backup Information CSV
        """"+$Vault.Name+""","""+$Redundancy+""","""+$Vault.Location+""","""+$ResourceGroupName+""","""+$VMName+""","""+$TotalSize+""","""+$Tag1+""","""+$Tag2+""","""+$Item.ProtectionPolicyName+""","""+$Item.ProtectionStatus+"""" |
        Out-File -Encoding ASCII -FilePath ".\Backup Vault Information.csv" -Append
        }
    }
}