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

resource "azurerm_automation_schedule" "backup_runbook_schedule" {
  name                    = "Daily_10PM"
  resource_group_name     = "${var.resource_group_name}"
  automation_account_name = "${azurerm_automation_account.automation_account.name}"
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = "${var.rubook_start_date}T22:00:00+00:00"
  description             = "Daily 10PM Schedule."
}

data "template_file" "jobschedule" {
  template = "${file("${path.module}/jobschedule.deploy.json")}"
}

resource "azurerm_template_deployment" "backup_job_schedule" {
  name                = "backup_job_schedule"
  resource_group_name = "${var.resource_group_name}"

  template_body = "${data.template_file.jobschedule.rendered}"

  parameters {
    "automation_account_name" = "${var.automation_account_name}"
    "schedule_name" = "Daily_10PM"
    "runbook_name" = "Azure_VM_Backup_Configuration"
    "script_param_location" = "${var.location}"
    "script_param_resource_group_name" = "${var.vault_resource_group_name}"
    "script_param_vault_prefix" = "${var.vault_name}"
  }

  deployment_mode = "Incremental"

  depends_on = [
    "azurerm_automation_runbook.backup_runbook",
    "azurerm_automation_schedule.backup_runbook_schedule",
  ]
}
