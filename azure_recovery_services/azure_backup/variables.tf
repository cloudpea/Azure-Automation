variable "automation_resource_group_name" {
  default     = "RG-WE-AUTOMATION-CLOUDPEA"
  description = "Resource Group Name for the Automation Resources."
}

variable "backup_resource_group_name" {
  default     = "RG-WE-BACKUP-CLOUDPEA"
  description = "Resource Group Name for the Backup Resources."
}

variable "location" {
  default     = "West Europe"
  description = "Location to Create the Recovery Services Vaults."
}

variable "automation_account_name" {
  default     = "AA-WE-CLOUDPEA-1"
  description = "The Name Prefix of the Recovery Services Vaults."
}

variable "vault_name" {
  default     = "RSV-WE-CLOUDPEA-1"
  description = "The Name Prefix of the Recovery Services Vaults."
}

variable "tier1_vm_count" {
  default     = 50
  description = "The number of Tier 1 Virtual Machines to Backup."
}

variable "tier2_vm_count" {
  default     = 50
  description = "The number of Tier 2 Virtual Machines to Backup."
}

variable "tier3_vm_count" {
  default     = 50
  description = "The number of Tier 3 Virtual Machines to Backup."
}

variable "tier4_vm_count" {
  default     = 50
  description = "The number of Tier 4 Virtual Machines to Backup."
}

variable "tag_owner" {
  default     = "Ryan Froggatt"
  description = "An Owner Tag for the Azure Backup Vaults."
}
