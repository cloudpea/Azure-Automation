# Create Automation Account
resource "azurerm_automation_account" "automation_account" {
  name                = "${var.automation_account_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  sku {
    name = "Basic"
  }
}

# Create Automation Account Runbook
resource "azurerm_automation_runbook" "runbook" {
  name                = "${var.rubook_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  account_name        = "${azurerm_automation_account.automation_account.name}"
  log_verbose         = "true"
  log_progress        = "true"
  runbook_type        = "PowerShell"

  publish_content_link {
    uri = "${var.rubook_uri}"
  }
}

# Create Automation Account Schedule
resource "azurerm_automation_schedule" "runbook_schedule" {
  name                    = "${var.schedule_name}"
  resource_group_name     = "${var.resource_group_name}"
  automation_account_name = "${azurerm_automation_account.automation_account.name}"
  frequency               = "${var.schedule_frequency}"
  interval                = 1
  timezone                = "UTC"
  start_time              = "${var.schedule_start_date}T${var.schedule_start_time}+00:00"
}

# Create Job Schedule ARM Template
data "template_file" "jobschedule" {
  template = "${file("${path.module}/jobschedule.deploy.json")}"
}

# Create Backup Runbook Job

resource "azurerm_template_deployment" "job_schedule" {
  name                = "job_schedule"
  resource_group_name = "${var.resource_group_name}"

  template_body = "${data.template_file.jobschedule.rendered}"

  parameters {
    "automation_account_name" = "${var.automation_account_name}"
    "schedule_name" = "${var.schedule_name}"
    "runbook_name" = "${var.rubook_name}"
    "script_param_location" = "${var.location}"
    "script_param_resource_group_name" = "${var.vault_resource_group_name}"
    "script_param_vault_prefix" = "${var.vault_name}"
  }

  deployment_mode = "Incremental"

  depends_on = [
    "azurerm_automation_runbook.runbook",
    "azurerm_automation_schedule.runbook_schedule",
  ]
}
