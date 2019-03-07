provider "azurerm" {
  subscription_id = "${var.hub_subscription_id}"
  alias           = "hub"
}

resource "azurerm_resource_group" "spoke-rg" {
  name     = "${var.spoke_resource_group_name}"
  location = "${var.location}"

  tags {
    "Application" = "Network"
    "Owner"       = "${var.owner_tag}"
    "Environment" = "${var.environment_tag}"
  }
}

resource "azurerm_virtual_network" "spoke-net" {
  name                = "${var.spoke_network_name}"
  resource_group_name = "${azurerm_resource_group.spoke-rg.name}"
  location            = "${azurerm_resource_group.spoke-rg.location}"
  dns_servers         = "${var.dns_servers}"
  address_space       = "${var.spoke_network_address_spaces}"

  tags {
    "Application" = "Network"
    "Owner"       = "${var.owner_tag}"
    "Environment" = "${var.environment_tag}"
  }
}

resource "azurerm_network_security_group" "spoke-default-nsg" {
  name                = "${var.spoke_network_name}-default-nsg"
  resource_group_name = "${azurerm_resource_group.spoke-rg.name}"
  location            = "${azurerm_resource_group.spoke-rg.location}"
  security_rule {
    name                         = "AllowInternalToAzure"
    priority                     = 1000
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = "${var.internal_network_address_spaces}"
    destination_address_prefixes = "${var.spoke_network_address_spaces}"
  }

  tags {
    "Application" = "Network"
    "Owner"       = "${var.owner_tag}"
    "Environment" = "${var.environment_tag}"
  }
}

resource "azurerm_subnet" "spoke-subnet-1" {
  name                      = "${var.spoke_subnet_1_name}"
  resource_group_name       = "${azurerm_resource_group.spoke-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.spoke-net.name}"
  address_prefix            = "${var.spoke_subnet_1_address_space}"
  network_security_group_id = "${azurerm_network_security_group.spoke-default-nsg.id}"
}

resource "azurerm_virtual_network_peering" "hub-to-spoke" {
  name                      = "hub-to-${azurerm_virtual_network.spoke-net.name}"
  resource_group_name       = "${var.hub_resource_group_name}"
  virtual_network_name      = "${var.hub_network_name}"
  remote_virtual_network_id = "${azurerm_virtual_network.spoke-net.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  depends_on = [
    "azurerm_subnet.spoke-subnet-1",
  ]
}

resource "azurerm_virtual_network_peering" "spoke-to-hub" {
  provider                  = "azurerm.hub"
  name                      = "${azurerm_virtual_network.spoke-net.name}-to-hub"
  resource_group_name       = "${azurerm_resource_group.spoke-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.spoke-net.name}"
  remote_virtual_network_id = "${var.hub_network_id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = "${var.use_remote_gateways}"

  depends_on = [
    "azurerm_subnet.spoke-subnet-1",
  ]
}
