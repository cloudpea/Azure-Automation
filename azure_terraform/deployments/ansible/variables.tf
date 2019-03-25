variable "resourcegroup_name" {
  type        = "string"
  default     = "RG-PRD-WE-ANSIBLE"
  description = "Resource Group Name for the Ansible Azure Resources."
}

variable "location" {
  type        = "string"
  default     = "West Europe"
  description = "Location to Create the Ansible Azure Resources."
}

variable "tag_application" {
  type        = "string"
  default     = "Ansible"
  description = "An Application Tag for the Ansible Azure Resources."
}

variable "tag_environment" {
  type        = "string"
  default     = "Production"
  description = "An Environment Tag for the Ansible Azure Resources."
}

variable "tag_criticality" {
  type        = "string"
  default     = "Tier 2"
  description = "A Criticality Tag for the Ansible Azure Resources."
}

variable "tag_owner" {
  type        = "string"
  default     = "DevOps Team"
  description = "An Owner Tag for the Ansible Azure Resources."
}

variable "vm_name" {
  type        = "string"
  default     = "VM-PRD-WE-ANSIBLE"
  description = "Name for the Ansible Azure Virtual Machine."
}

variable "vm_size" {
  type        = "string"
  default     = "Standard_B1s"
  description = "VM Size for the Ansible Azure Virtual Machine."
}

variable "vm_username" {
  type        = "string"
  default     = "ansible-admin"
  description = "Admin username for the Ansible Azure Virtual Machine."
}

variable "vm_password" {
  type        = "string"
  description = "Admin password for the Ansible Azure Virtual Machine."
}

variable "ansible_username" {
  type        = "string"
  default     = "ansible"
  description = "Username for the Ansible Service Account."
}

variable "ansible_git_url" {
  type        = "string"
  description = "Github Repository URL for the Ansible Playbooks."
}

variable "ansible_git_token" {
  type        = "string"
  description = "Github OAuth Token for the Repository."
}

variable "corporate_ip" {
  type        = "string"
  default     = "10.0.1.10"
  description = "IP Address to allow SSH connections from."
}

variable "subnet_id" {
  type        = "string"
  description = "Full subnet ID to deploy the Ansible Azure Virtual Machine into."
}
