# Configure the Microsoft Azure Resource Manager Provider
provider "azurerm" {
  version = "=1.22.0"
}

# Set Azure Subsciption
data "azurerm_subscription" "current" {}

# Create DevOps Agent VMs
module "devops_agent" {
  source              = "../../modules/devops_agent"
  resourcegroup_name  = "${var.resourcegroup_name}"
  location            = "${var.location}"
  tag_application     = "${var.tag_application}"
  tag_environment     = "${var.tag_environment}"
  tag_criticality     = "${var.tag_criticality}"
  tag_owner           = "${var.tag_owner}"
  vm_name             = "${var.vm_name}"
  vm_size             = "${var.vm_size}"
  vm_username         = "${var.vm_username}"
  vm_password         = "${var.vm_password}"
  corporate_ip        = "${var.corporate_ip}"
  subnet_id           = "${var.subnet_id}"
  devops_organisation = "${var.devops_organisation}"
  devops_pat          = "${var.devops_pat}"
  devops_pool_name    = "${var.devops_pool_name}"
}

# Outputs