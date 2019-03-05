Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Region Location - westeurope, ukwest")]
  [string]$location,

  [Parameter(Mandatory=$True, HelpMessage="A Prefix for the Recovery Services Vault")]
  [string]$vault_prefix,

  [Parameter(Mandatory=$True, HelpMessage="Resource Group Name of the Recovery Services Vault")]
  [securestring]$resource_group_name
)

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Configuring Azure Virtual Machine Backups Based on Backup Tier Tag..."
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
        $vault = Get-AzRecoveryServicesVault -Name ($vault_prefix + "-" + $Storageredundancy.$tier) -resource_group_name $resource_group_name
        Set-AzRecoveryServicesVaultContext -Vault $vault

        ## We replace the # and £ with the tier number
        $base_policy_name = "BP-TIER#-£-"
        $policy_name = $base_policy_name.Replace("#", $tier)
        $policy_name = $policy_name.Replace("£", $Storageredundancy.$tier)
        #build the full name out, because its less clunky
        $full_policy_name = $policy_name + ([math]::floor($itemcount.$tier++ /  40) + 1).ToString()
        #and implement
        $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $full_policy_name
        Enable-AzRecoveryServicesBackupProtection -Name $VM.Name -resource_group_name $VM.resource_group_name -Policy $policy
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
