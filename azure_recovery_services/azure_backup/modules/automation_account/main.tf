resource "azurerm_automation_account" "automation_account" {
  name                = "${var.automation_account_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  sku {
    name = "Basic"
  }
}

resource "azurerm_automation_runbook" "backup_runbook" {
  name                = "Azure_VM_Backup_Configuration"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  account_name        = "${azurerm_automation_account.automation_account.name}"
  log_verbose         = "true"
  log_progress        = "true"
  description         = "This is a Runbook to Configure Azure VM Backups Based on a Backup Tier Tag."
  runbook_type        = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/cloudpea/Azure-Automation/master/azure_recovery_services/azure_backup/vm_backup_config.ps1"
  }
}