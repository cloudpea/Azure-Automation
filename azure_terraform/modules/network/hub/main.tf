### Create the main Hub resources ###

resource "azurerm_resource_group" "hub-rg" {
  name     = "${var.hub_resource_group_name}"
  location = "${var.hub_location}"

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_virtual_network" "hub-net" {
  name                = "${var.hub_network_name}"
  resource_group_name = "${azurerm_resource_group.hub-rg.name}"
  location            = "${azurerm_resource_group.hub-rg.location}"
  dns_servers         = "${var.dns_servers}"
  address_space       = "${var.hub_network_address_spaces}"

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_network_security_group" "hub-defualt-nsg" {
  name                = "${azurerm_virtual_network.hub-net.name}-default-nsg"
  resource_group_name = "${azurerm_resource_group.hub-rg.name}"
  location            = "${azurerm_resource_group.hub-rg.location}"

  security_rule {
    name                         = "AllowInternalToAzure"
    priority                     = 1000
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = "${var.internal_network_address_spaces}"
    destination_address_prefixes = "${var.hub_network_address_spaces}"
  }

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_subnet" "hub-mgmt-sn" {
  name                      = "mgmt-sn"
  resource_group_name       = "${azurerm_virtual_network.hub-net.resource_group_name}"
  virtual_network_name      = "${azurerm_virtual_network.hub-net.name}"
  address_prefix            = "${var.hub_management_subnet_address_space}"
  network_security_group_id = "${azurerm_network_security_group.hub-defualt-nsg.id}"
}

resource "azurerm_subnet" "hub-ad-sn" {
  name                      = "ad-sn"
  resource_group_name       = "${azurerm_virtual_network.hub-net.resource_group_name}"
  virtual_network_name      = "${azurerm_virtual_network.hub-net.name}"
  address_prefix            = "${var.hub_active_directory_subnet_address_space}"
  network_security_group_id = "${azurerm_network_security_group.hub-defualt-nsg.id}"
}

resource "azurerm_subnet" "hub-shared-sn" {
  name                      = "shared-sn"
  resource_group_name       = "${azurerm_virtual_network.hub-net.resource_group_name}"
  virtual_network_name      = "${azurerm_virtual_network.hub-net.name}"
  address_prefix            = "${var.hub_shared_resource_subnet_address_space}"
  network_security_group_id = "${azurerm_network_security_group.hub-defualt-nsg.id}"
}

resource "azurerm_management_lock" "hub-net-lock" {
  name       = "${var.hub_network_name}-lock"
  scope      = "${azurerm_virtual_network.hub-net.id}"
  lock_level = "CanNotDelete"
  notes      = "Prevent deletion of VNet."
}

### Gateway Subnet ###

resource "azurerm_subnet" "hub-gw-sn" {
  count                = "${signum(var.create_vpn_gateway + var.create_er_gateway)}"
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_virtual_network.hub-net.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.hub-net.name}"
  address_prefix       = "${var.hub_gateway_subnet_address_space}"
}

### VPN Gateway ###

resource "azurerm_public_ip" "hub-vpn-gw-pip" {
  count               = "${signum(var.create_vpn_gateway)}"
  name                = "${azurerm_virtual_network.hub-net.name}-vpn-gw-pip"
  resource_group_name = "${azurerm_virtual_network.hub-net.resource_group_name}"
  location            = "${azurerm_virtual_network.hub-net.location}"
  allocation_method   = "Dynamic"

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_virtual_network_gateway" "hub-vpn-gw" {
  count               = "${signum(var.create_vpn_gateway)}"
  name                = "${azurerm_virtual_network.hub-net.name}-vpn-gw"
  resource_group_name = "${azurerm_virtual_network.hub-net.resource_group_name}"
  location            = "${azurerm_virtual_network.hub-net.location}"
  sku                 = "Standard"
  type                = "VPN"
  vpn_type            = "${var.hub_vpn_type}"
  enable_bgp          = "${var.is_bgp_enabled}"

  bgp_settings {
    asn = "${var.hub_vpn_gateway_bgp_asn}"
  }

  ip_configuration {
    public_ip_address_id = "${element(azurerm_public_ip.hub-vpn-gw-pip.*.id, count.index)}"
    subnet_id            = "${element(azurerm_subnet.hub-gw-sn.*.id, count.index)}"
  }

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }

  depends_on = [
    "azurerm_subnet.hub-mgmt-sn",
    "azurerm_subnet.hub-ad-sn",
    "azurerm_subnet.hub-shared-sn",
    "azurerm_subnet.hub-gw-sn",
  ]
}

resource "azurerm_local_network_gateway" "hub-local-gw" {
  count               = "${signum(var.create_vpn_gateway)}"
  name                = "${var.hub_local_gateway_name}"
  resource_group_name = "${element(azurerm_virtual_network_gateway.hub-vpn-gw.*.resource_group_name, count.index)}"
  location            = "${element(azurerm_virtual_network_gateway.hub-vpn-gw.*.location, count.index)}"
  gateway_address     = "${var.hub_local_gateway_address}"
  address_space       = "${var.hub_local_gateway_address_spaces}"

  bgp_settings {
    asn                 = "${var.hub_local_gateway_bgp_asn}"
    bgp_peering_address = "${var.hub_local_gateway_bgp_peering_address}"
  }

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_virtual_network_gateway_connection" "hub-local-gw-connection" {
  count                      = "${signum(var.create_vpn_gateway)}"
  name                       = "${var.hub_vpn_connection_name}"
  resource_group_name        = "${element(azurerm_virtual_network_gateway.hub-vpn-gw.*.resource_group_name, count.index)}"
  location                   = "${element(azurerm_virtual_network_gateway.hub-vpn-gw.*.location, count.index)}"
  virtual_network_gateway_id = "${element(azurerm_virtual_network_gateway.hub-vpn-gw.*.id, count.index)}"
  local_network_gateway_id   = "${element(azurerm_local_network_gateway.hub-local-gw.*.id, count.index)}"
  type                       = "IPSec"
  enable_bgp                 = "${var.is_bgp_enabled}"
  shared_key                 = "${var.hub_vpn_connection_shared_key}"

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_management_lock" "hub-vpn-gw-lock" {
  count      = "${signum(var.create_vpn_gateway)}"
  name       = "${element(azurerm_virtual_network_gateway.hub-vpn-gw.*.name, count.index)}-lock"
  scope      = "${element(azurerm_virtual_network_gateway.hub-vpn-gw.*.id, count.index)}"
  lock_level = "CanNotDelete"
  notes      = "Prevent deletion of VPN Gateway."
}

### ExpressRoute Gateway ###

resource "azurerm_public_ip" "hub-er-gw-pip" {
  count               = "${signum(var.create_er_gateway)}"
  name                = "${azurerm_virtual_network.hub-net.name}-er-gw-pip"
  resource_group_name = "${azurerm_virtual_network.hub-net.resource_group_name}"
  location            = "${azurerm_virtual_network.hub-net.location}"
  allocation_method   = "Dynamic"

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_virtual_network_gateway" "hub-er-gw" {
  count               = "${signum(var.create_er_gateway)}"
  name                = "${azurerm_virtual_network.hub-net.name}-er-gw"
  resource_group_name = "${azurerm_virtual_network.hub-net.resource_group_name}"
  location            = "${azurerm_virtual_network.hub-net.location}"
  sku                 = "Standard"
  type                = "ExpressRoute"

  ip_configuration {
    public_ip_address_id = "${azurerm_public_ip.hub-er-gw-pip.id}"
    subnet_id            = "${azurerm_subnet.hub-gw-sn.id}"
  }

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }

  depends_on = [
    "azurerm_subnet.hub-mgmt-sn",
    "azurerm_subnet.hub-ad-sn",
    "azurerm_subnet.hub-shared-sn",
    "azurerm_subnet.hub-gw-sn",
  ]
}

resource "azurerm_express_route_circuit" "hub-er-circuit" {
  count                 = "${signum(var.create_er_gateway)}"
  name                  = "${azurerm_virtual_network.hub-net.name}-er-circuit-1"
  resource_group_name   = "${azurerm_virtual_network.hub-net.resource_group_name}"
  location              = "${azurerm_virtual_network.hub-net.location}"
  service_provider_name = "${var.service_provider_name}"
  peering_location      = "${var.peering_location}"
  bandwidth_in_mbps     = "${var.bandwidth_in_mbps}"

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }

  tags {
    "Owner"       = "${var.owner_tag}"
    "Application" = "Network"
    "Environment" = "Production"
  }
}

resource "azurerm_management_lock" "hub-er-gw-lock" {
  count      = "${signum(var.create_er_gateway)}"
  name       = "${azurerm_virtual_network_gateway.hub-er-gw.name}-lock"
  scope      = "${azurerm_virtual_network_gateway.hub-er-gw.id}"
  lock_level = "CanNotDelete"
  notes      = "Prevent deletion of ER Gateway."
}

#Outputs
output "hub-rg-name" {
  value = "${azurerm_resource_group.hub-rg.name}"
}

output "hub-net-name" {
  value = "${azurerm_virtual_network.hub-net.name}"
}

output "hub-net-id" {
  value = "${azurerm_virtual_network.hub-net.id}"
}

output "hub-gw-sn-count" {
  value = "${azurerm_subnet.hub-gw-sn.count}"
}
