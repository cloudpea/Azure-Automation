Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Region Location - westeurope, ukwest")]
  [string]$location,

  [Parameter(Mandatory=$True, HelpMessage="Resource Group Name of the Recovery Services Vault")]
  [string]$resource_group_name,

  [Parameter(Mandatory=$True, HelpMessage="A Prefix for the Recovery Services Vault")]
  [string]$vault_prefix
)

## Login with RunAs Account
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Loggind in to Azure with RunAs Account..."
$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID -ApplicationID $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint
Select-AzSubscription -SubscriptionId $connection.SubscriptionID
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logged in to Azure Successfully!"

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Configuring Azure Virtual Machine Backups Based on Backup Tier Tag..."
## Create Blank Item Count and Storage Redundancy Hashtables
$itemcount = @{}
$Storageredundancy = @{ 1="GRS"; 2="GRS"; 3="LRS"; 4="LRS"}

## Add VMs to Vault and Backup Policy Depending on Backup Tier Tag
foreach ($VM in Get-AzVM | Where-Object {$_.Tags.Backup -ne $null}) {
    Write-Output ("Configuring VM Backup - "+$VM.Name)
    
    $crit_string = $VM.Tags.Backup

    ## Check Tag Matches the Regex Format
    if ($crit_string -match "Tier [1-4]") {

        #Get Tier Value from Tag
        [int]$tier = $crit_string.Split(" ")[1]

        ## If the Tier Key hasnt been created then create it
        if (-not $itemcount.$tier) {
            $itemcount.$tier = 0
        }
        $vault = Get-AzRecoveryServicesVault -Name ($vault_prefix + "-" + $Storageredundancy.$tier) -ResourceGroupName $resource_group_name
        Set-AzRecoveryServicesVaultContext -Vault $vault

        ## Replace the # with the Tier Number and £ with the Storage Redundancy
        $base_policy_name = "BP-TIER#-£-"
        $policy_name = $base_policy_name.Replace("#", $tier)
        $policy_name = $policy_name.Replace("£", $Storageredundancy.$tier)
    
        #Add the Policy Number (Due to policies being limited to 40 backup items)
        $full_policy_name = $policy_name + ([math]::floor($itemcount.$tier++ /  40) + 1).ToString()

        # Enable Protection for the VM
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
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Azure Virtual Machine Backups Configured Successfully!"
