provider "azurerm" {
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
  version         = "~> 1.22"
}

### Create a management group and add policies ###

module "policies" {
  source                             = "../../modules/policies"
  name                               = "policies"
  customer_prefix                = "${var.customer_prefix}"
  management_group_subscriptions = "${var.management_group_subscriptions}"
}