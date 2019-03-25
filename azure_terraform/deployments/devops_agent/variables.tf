variable "resourcegroup_name" {
  type    = "string"
  default = "RG-PRD-UKS-DEVOPS"
  description = "Resource Group Name for the Azure Resources."
}

variable "location" {
  type = "string"
  default = "UK South"
  description = "Location to Create the Azure Resources."
}

variable "tag_application" {
  type    = "string"
  default = "Azure DevOps"
  description = "An Application Tag for the Azure Resources."
}

variable "tag_environment" {
  type    = "string"
  default = "Production"
  description = "An Environment Tag for the Azure Resources."

}

variable "tag_criticality" {
  type    = "string"
  default = "Tier 2"
  description = "An Criticality Tag for the Azure Resources."
}

variable "tag_owner" {
  type    = "string"
  default = "DevOps Team"
  description = "An Owner Tag for the Azure Resources."
}

variable "vm_name" {
  type    = "string"
  default = "VM-PRD-UKS-DEVOPS-AGENT"
  description = "Name for the DevOps Agent Virtual Machine."
}

variable "vm_size" {
  type    = "string"
  default = "Standard_B1s"
  description = "VM Size for the DevOps Agent Virtual Machines."
}

variable "vm_username" {
  type    = "string"
  default = "cloudpea-admin"
  description = "Admin username for the DevOps Agent Virtual Machines."
}

variable "vm_password" {
  type = "string"
  description = "Admin password for the DevOps Agent Virtual Machines."
}

variable "corporate_ip" {
  type    = "string"
  default = "10.0.1.10"
  description = "IP Address to allow SSH connections from."
}

variable "subnet_id" {
  type = "string"
  description = "Full subnet ID to deploy the DevOps Agent Virtual Machines."
}

variable "devops_organisation" {
  type    = "string"
  default = "cloupea"
  description = "Azure DevOps Orgasnisation Name."
}

variable "devops_pat" {
  type = "string"
  description = "Azure DevOps Personal Access Token."
}

variable "devops_pool_name" {
  type    = "string"
  default = "cloudpea"
  description = "Azure DevOps Agent Pool Name."
}