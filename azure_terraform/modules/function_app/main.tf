# Create Hub Resource Group
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags {
    "Owner"            = "${var.owner_tag}"
    "Application"      = "${var.application_tag}"
    "Environment"      = "${var.environment_tag}"
  }
}



# Create Function App Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                     = "${var.storage_account_name}"
  resource_group_name      = "${azurerm_resource_group.resource_group.name}"
  location                 = "${azurerm_resource_group.resource_group.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    "Owner"            = "${var.owner_tag}"
    "Application"      = "${var.application_tag}"
    "Application Role" = "Storage"
    "Environment"      = "${var.environment_tag}"
  }
}

# Create Function App Service Plan
resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.app_service_plan_name}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  location            = "${azurerm_resource_group.resource_group.location}"

  sku {
    tier = "${var.service_plan_tier}"
    size = "${var.service_plan_size}"
  }

  tags {
    "Owner"            = "${var.owner_tag}"
    "Application"      = "${var.application_tag}"
    "Application Role" = "Functions"
    "Environment"      = "${var.environment_tag}"
  }
}

# Create Function App
resource "azurerm_function_app" "function_app" {
  name                      = "${var.function_app_name}"
  resource_group_name       = "${azurerm_resource_group.resource_group.name}"
  location                  = "${azurerm_resource_group.resource_group.location}"
  app_service_plan_id       = "${azurerm_app_service_plan.app_service_plan.id}"
  storage_connection_string = "${azurerm_storage_account.storage_account.primary_connection_string}"

  tags {
    "Owner"            = "${var.owner_tag}"
    "Application"      = "${var.application_tag}"
    "Application Role" = "Functions"
    "Environment"      = "${var.environment_tag}"
  }
}

