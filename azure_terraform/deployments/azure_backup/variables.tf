variable "automation_resource_group_name" {
  type        = "string"
  default     = "RG-WE-AUTOMATION-CLOUDPEA"
  description = "Resource Group Name for the Automation Resources."
}

variable "backup_resource_group_name" {
  type        = "string"
  default     = "RG-WE-BACKUP-CLOUDPEA"
  description = "Resource Group Name for the Backup Resources."
}

variable "location" {
  type        = "string"
  default     = "West Europe"
  description = "Location to Create the Recovery Services Vaults."
}

variable "automation_account_name" {
  type        = "string"
  default     = "AA-WE-CLOUDPEA-1"
  description = "The Name for the Automation Account."
}

variable "rubook_name" {
  type        = "string"
  description = "The Name for the Automation Account Runbook."
}

variable "rubook_uri" {
  type        = "string"
  description = "The full URI to the PowerShell Script Location."
}

variable "schedule_name" {
  type        = "string"
  description = "The Name for the Automation Account Schedule."
}

variable "schedule_frequency" {
  type        = "string"
  description = "The Frequency the Schedule runs on - OneTime, Day, Hour, Week, or Month"
}

variable "schedule_start_date" {
  type        = "string"
  description = "The Date for the Runbook to Start in the format - 2019-03-31"
}

variable "schedule_start_date" {
  type        = "string"
  description = "The Time for the Runbook to Start in the format - 22:00:00"
}

variable "vault_name" {
  type        = "string"
  default     = "RSV-WE-CLOUDPEA-1"
  description = "The Name Prefix of the Recovery Services Vaults."
}

variable "tier1_vm_count" {
  type        = "string"
  default     = "10"
  description = "The number of Tier 1 Virtual Machines to Backup."
}

variable "tier2_vm_count" {
  type        = "string"
  default     = "10"
  description = "The number of Tier 2 Virtual Machines to Backup."
}

variable "tier3_vm_count" {
  type        = "string"
  default     = "10"
  description = "The number of Tier 3 Virtual Machines to Backup."
}

variable "tier4_vm_count" {
  type        = "string"
  default     = "10"
  description = "The number of Tier 4 Virtual Machines to Backup."
}

variable "tag_owner" {
  type        = "string"
  default     = "Backup Team"
  description = "An Owner Tag for the Azure Backup Vaults."
}
