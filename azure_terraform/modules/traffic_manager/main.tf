resource "random_id" "unique_id" {
  keepers = {
    azi_id = "${var.profile_name}"
  }
  
  byte_length = 8
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags {
    "Owner"            = "${var.owner_tag}"
    "Application"      = "${var.application_tag}"
    "Environment"      = "${var.environment_tag}"
  }
}

resource "azurerm_traffic_manager_profile" "traffic_manager_profile" {
  name                   = "${var.profile_name}-${random_id.unique_id.hex}"
  resource_group_name    = "${azurerm_resource_group.resource_group.name}"
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "${random_id.unique_id.hex}"
    ttl           = 100
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"
  }

  tags = {
    environment = "${var.environment_tag}"
  }
}
