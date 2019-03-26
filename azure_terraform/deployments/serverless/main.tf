provider "azurerm" {
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
  version         = "~> 1.22"
}

provider "random" {}

### Create a management group and add policies ###
module "traffic_manager" {
  source = "../../modules/traffic_manager"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  owner_tag           = "${var.owner_tag}"
  application_tag     = "${var.application_tag}"
  environment_tag     = "${var.environment_tag}"
  profile_name        = "${var.profile_name}"
}

module "function_app" {
  source = "../../modules/function_app"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  owner_tag             = "${var.owner_tag}"
  application_tag       = "${var.application_tag}"
  environment_tag       = "${var.environment_tag}"
  storage_account_name  = "${var.storage_account_name}"
  app_service_plan_name = "${var.app_service_plan_name}"
  service_plan_tier     = "${var.service_plan_tier}"
  service_plan_size     = "${var.service_plan_size}"
  function_app_name     = "${var.function_app_name}"
}
