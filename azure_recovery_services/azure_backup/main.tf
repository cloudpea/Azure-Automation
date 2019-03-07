# Configure the Microsoft Azure Resource Manager Provider
provider "azurerm" {
  version = "=1.22.0"
}

# Configure the Null Provider
provider "null" {
  version = "=2.1.0"
}

# Configure the Template Provider
provider "template" {
  version = "=2.1.0"
}

# Set Azure Subsciption
data "azurerm_subscription" "current" {}

#Create Azure Resource Groups
resource "azurerm_resource_group" "backup_resource_group" {
  name     = "${var.backup_resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_resource_group" "automation_resource_group" {
  name     = "${var.automation_resource_group_name}"
  location = "${var.location}"
}

# Create Azure Backup Solution
module "azure_backup" {
  source              = "modules/azure_backup"
  resource_group_name = "${azurerm_resource_group.backup_resource_group.name}"
  location            = "${var.location}"
  vault_name          = "${var.vault_name}"
  tier1_policy_count  = "${format(floor(var.tier1_vm_count /40 +1))}"
  tier2_policy_count  = "${format(floor(var.tier2_vm_count /40 +1))}"
  tier3_policy_count  = "${format(floor(var.tier3_vm_count /40 +1))}"
  tier4_policy_count  = "${format(floor(var.tier4_vm_count /40 +1))}"
  tag_owner           = "${var.tag_owner}"
}

# Create Azure Automation Account & Runbook
module "azure_automation" {
  source                    = "modules/automation_account"
  resource_group_name       = "${azurerm_resource_group.automation_resource_group.name}"
  location                  = "${var.location}"
  automation_account_name   = "${var.automation_account_name}"
  rubook_start_date         = "${var.rubook_start_date}"
  vault_name                = "${var.vault_name}"
  vault_resource_group_name = "${azurerm_resource_group.backup_resource_group.name}"
}
